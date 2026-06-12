#!/usr/bin/env bash
# deploy_claude_config.sh
# GitHub の master-repo/claude/ から CLAUDE 設定ファイルを取得して ~/.claude/ に配置するスクリプト（Mac版）
#
# リポジトリ構成:
#   master-repo/
#   └── claude/
#       ├── CLAUDE.md           <- 共通設定
#       ├── CLAUDE.surface.md   <- Surface 専用設定
#       └── CLAUDE.mac.md       <- Mac 専用設定
#
# 使い方:
#   bash deploy_claude_config.sh                    # GitHub main ブランチから取得（通常はこれ）
#   bash deploy_claude_config.sh -b develop         # ブランチ指定
#   bash deploy_claude_config.sh --offline          # ローカルファイルのみ使用（ネット不要）
#
# 事前準備:
#   以下2変数を自分のリポジトリ情報に書き換えること

# =====================================================================
# ★ 設定: 自分のリポジトリ情報に書き換えること
# =====================================================================
GITHUB_USER="YOUR_GITHUB_USERNAME"   # 例: "yoshinobu"
GITHUB_REPO="master-repo"            # リポジトリ名
REMOTE_DIR="claude"                  # リポジトリ内のフォルダパス
# =====================================================================

BRANCH="main"
OFFLINE=false
CLAUDE_DIR="$HOME/.claude"

# 引数解析
while [[ $# -gt 0 ]]; do
  case "$1" in
    -b|--branch) BRANCH="$2"; shift 2 ;;
    --offline)   OFFLINE=true; shift ;;
    *) echo "不明なオプション: $1"; exit 1 ;;
  esac
done

# ファイル名マッピング: リモートファイル名 → ローカル保存名
declare -A FILE_MAP=(
  ["CLAUDE.md"]="CLAUDE.common.md"
  ["CLAUDE.surface.md"]="CLAUDE.surface.md"
  ["CLAUDE.mac.md"]="CLAUDE.mac.md"
)

mkdir -p "$CLAUDE_DIR"

# -----------------------------------------------------------------
# ダウンロード関数
# -----------------------------------------------------------------
fetch_file() {
  local remote_path="$1"
  local url="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${BRANCH}/${remote_path}"
  local headers=()

  # プライベートリポジトリ対応: 環境変数 GITHUB_PAT が設定されていれば Bearer 認証を付与
  if [[ -n "$GITHUB_PAT" ]]; then
    headers=(-H "Authorization: Bearer $GITHUB_PAT")
  fi

  local http_code
  http_code=$(curl -sS -o /tmp/_claude_deploy_tmp -w "%{http_code}" "${headers[@]}" "$url")

  case "$http_code" in
    200) cat /tmp/_claude_deploy_tmp ;;
    404) echo "ERROR:404: ${remote_path} が見つかりません。リポジトリ名・ブランチ・ファイル名を確認してください。URL: $url" >&2; return 1 ;;
    401|403) echo "ERROR:${http_code}: プライベートリポジトリです。GITHUB_PAT を設定してください。例: export GITHUB_PAT='ghp_xxx'" >&2; return 1 ;;
    *) echo "ERROR:${http_code}: ${remote_path} の取得に失敗しました。" >&2; return 1 ;;
  esac
}

# -----------------------------------------------------------------
# メイン処理
# -----------------------------------------------------------------
echo ""

if $OFFLINE; then
  # ---- ローカルモード ----
  echo "オフラインモード: スクリプトと同じフォルダのファイルを使用します。"
  echo ""

  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  missing=false
  for remote_name in "${!FILE_MAP[@]}"; do
    [[ -f "$SCRIPT_DIR/$remote_name" ]] || { echo "  [WARNING] ローカルファイルが見つかりません: $SCRIPT_DIR/$remote_name"; missing=true; }
  done
  $missing && { echo "スクリプトと同じフォルダに CLAUDE.md / CLAUDE.surface.md / CLAUDE.mac.md を置いてください。"; exit 1; }

  for remote_name in "${!FILE_MAP[@]}"; do
    local_name="${FILE_MAP[$remote_name]}"
    cp "$SCRIPT_DIR/$remote_name" "$CLAUDE_DIR/$local_name"
    echo "  [ローカル] $remote_name → $CLAUDE_DIR/$local_name"
  done

else
  # ---- GitHub モード ----
  if [[ "$GITHUB_USER" == "YOUR_GITHUB_USERNAME" ]]; then
    echo "エラー: スクリプト冒頭の GITHUB_USER を設定してください。"
    exit 1
  fi

  echo "GitHub からダウンロード中..."
  echo "  リポジトリ : https://github.com/${GITHUB_USER}/${GITHUB_REPO}"
  echo "  フォルダ   : ${REMOTE_DIR}/"
  echo "  ブランチ   : ${BRANCH}"
  [[ -n "$GITHUB_PAT" ]] && echo "  認証       : GITHUB_PAT 使用（プライベートリポジトリ）"
  echo ""

  all_success=true
  for remote_name in "${!FILE_MAP[@]}"; do
    remote_path="${REMOTE_DIR}/${remote_name}"
    local_name="${FILE_MAP[$remote_name]}"
    content=$(fetch_file "$remote_path") || { all_success=false; continue; }
    printf "%s" "$content" > "$CLAUDE_DIR/$local_name"
    echo "  [OK] $remote_path → $CLAUDE_DIR/$local_name"
  done

  $all_success || { echo ""; echo "一部ファイルの取得に失敗しました。上記の警告を確認してください。"; exit 1; }
fi

# Mac 用アクティブ設定を CLAUDE.md として配置
# （Claude Code は ~/.claude/CLAUDE.md を読み込む）
cp "$CLAUDE_DIR/CLAUDE.mac.md" "$CLAUDE_DIR/CLAUDE.md"

# -----------------------------------------------------------------
# 結果表示
# -----------------------------------------------------------------
echo ""
echo "配置完了:"
echo "  $CLAUDE_DIR/CLAUDE.md          <- Mac 用アクティブ設定（Claude Code が読込）"
echo "  $CLAUDE_DIR/CLAUDE.mac.md      <- Mac 設定（参照用）"
echo "  $CLAUDE_DIR/CLAUDE.surface.md  <- Surface 設定（参照用）"
echo "  $CLAUDE_DIR/CLAUDE.common.md   <- 共通設定（参照用）"
echo ""
echo "次のステップ: ~/master-repo の Python 仮想環境を構築してください（CLAUDE.mac.md セクション4参照）"
echo ""

# =================================================================
# プライベートリポジトリの場合
# =================================================================
# PAT（Personal Access Token）を環境変数にセットしてから実行してください。
# スクリプトにトークンを直書きしないこと。
#
# 【セッション内のみ有効】
#   export GITHUB_PAT="ghp_xxxxxxxxxxxx"
#   bash deploy_claude_config.sh
#
# 【永続化（~/.zshrc に追記）】
#   export GITHUB_PAT="ghp_xxxxxxxxxxxx"
#   # 設定後: source ~/.zshrc
#
# PAT 発行: GitHub → Settings → Developer settings
#           → Personal access tokens → Fine-grained tokens
#           必要なスコープ: Contents (read)
# =================================================================
