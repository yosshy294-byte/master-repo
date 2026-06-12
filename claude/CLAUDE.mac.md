# CLAUDE.mac.md — MacBook Air 専用設定

> **デバイス**: MacBook Air (M5 / macOS / 24GB RAM / SSD 512GB)
> **リポジトリパス**: `~/master-repo`
> **Claude 設定ファイル**: `~/master-repo/claude/`
> **リモート**: GitHub `master-repo` (private / 作成済み)
> **共通設定**: `CLAUDE.md` を必ず併せて参照すること
> **最終更新**: 2026-06-11
> **iPhone / iPad**: デフォルト設定のまま使用（カスタム設定なし）

---

## 1. パス構成

| 用途 | パス |
|---|---|
| リポジトリルート | `~/master-repo` |
| Claude 設定ファイル（本ファイル等） | `~/master-repo/claude/` |
| Claude Code グローバル設定（自動配置） | `~/.claude/CLAUDE.md` |
| Python ソース | `~/master-repo/python3/src/` |
| 仮想環境 | `~/master-repo/.venv/` |

> **仮定 C1**: リポジトリの配置先は以下2ケースから選択する（初回セットアップ前に決定すること）。
>
> **ケースA — `~/master-repo` に直接配置（推奨）**: iCloud 管理外。パスがシンプルで Git 操作が安定する。
>
> **ケースB — iCloud Drive 配下に配置**: ファイルが iCloud に同期される。パスにスペースが含まれるためシンボリックリンクが必須。セクション5「ケースB」を参照。

### deploy_claude_config.sh について

`master-repo/claude/` の MD ファイルを `~/.claude/` へ取得・配置するスクリプト（Mac 版）。

> **⚠️ 実行前の必須手順**
> 1. GitHub に `claude/` フォルダの全ファイルがアップロード済みであること
> 2. スクリプト冒頭の `GITHUB_USER` を自分の GitHub アカウント名に書き換えること
> 3. ケースBの場合はシンボリックリンク作成後に実行すること

```zsh
# 1. スクリプトを編集して GITHUB_USER を設定
nano ~/master-repo/claude/deploy_claude_config.sh
# GITHUB_USER="YOUR_GITHUB_USERNAME"  ← 実際のアカウント名に変更

# 2. 実行
cd ~/master-repo/claude
bash deploy_claude_config.sh

# 3. 配置確認
head -5 ~/.claude/CLAUDE.md
```

---

## 2. CLI 設定（Mac）

### VS Code — `code` コマンドの PATH 設定（初回必須）

```
VS Code 内: Cmd + Shift + P
→ "Shell Command: Install 'code' command in PATH" を実行
```

```zsh
which code   # /usr/local/bin/code が出力されること
```

### VS Code ワークスペース設定

```jsonc
// .vscode/settings.json
{
  "terminal.integrated.defaultProfile.osx": "zsh",
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
  "editor.formatOnSave": true,
  "files.eol": "\n",
  "files.encoding": "utf8"
}
```

### Zsh / iTerm2 設定（`~/.zshrc` に追記）

```zsh
# リポジトリルートへ移動
alias repo='cd "$HOME/master-repo"'

# Claude 設定フォルダへ移動
alias claudedir='cd "$HOME/master-repo/claude"'

# Python 仮想環境 activate
alias venv='source "$HOME/master-repo/.venv/bin/activate"'

# Git 同期ショートカット（変更なし時は commit をスキップ）
gsync() {
    cd "$HOME/master-repo" || return
    git pull
    if [[ -n $(git status --porcelain) ]]; then
        git add .
        git commit -m "sync: $(date +%Y-%m-%d)"
    fi
    git push
    cd - > /dev/null
}

alias gs='git status'
alias gp='git push'
alias gl='git log --oneline -10'
```

> **コンフリクト発生時**: gsync が途中で止まる。`git status` で競合ファイルを確認し手動解消後、`gsync` を再実行すること。

### tmux 設定（Homebrew 必須）

> **仮定 C2**: tmux は Homebrew でインストール済み（`brew install tmux`）。
> **注意**: `dev_session.sh` はリポジトリ内の `python3/src/dev_session.sh` を使用する。clone 後に存在しない場合は下記内容で手動作成すること。

```bash
# python3/src/dev_session.sh（リポジトリにコミット済みまたは手動作成）
#!/usr/bin/env bash
SESSION="dev"
tmux has-session -t "$SESSION" 2>/dev/null && tmux attach -t "$SESSION" && exit

if ! command -v code &>/dev/null; then
    echo "警告: 'code' コマンドが PATH に見つかりません。"
    echo "VS Code で Cmd+Shift+P → 'Install code command in PATH' を実行してください。"
    exit 1
fi

REPO="$HOME/master-repo"
tmux new-session -d -s "$SESSION" -n editor
tmux send-keys -t "$SESSION:editor" "cd '$REPO' && code ." Enter
tmux new-window -t "$SESSION" -n terminal
tmux split-window -t "$SESSION:terminal" -h
tmux send-keys -t "$SESSION:terminal.left"  "cd '$REPO' && source .venv/bin/activate" Enter
tmux send-keys -t "$SESSION:terminal.right" "cd '$REPO' && git status" Enter
tmux attach -t "$SESSION"
```

```zsh
# 初回のみ（実行権限の付与）
chmod +x ~/master-repo/python3/src/dev_session.sh

# ~/.zshrc に追記
alias dev='bash ~/master-repo/python3/src/dev_session.sh'
```

---

## 3. PostgreSQL

<!-- [DISABLED: PostgreSQL — DB設計確定待ち] -->
<!--
cd "$HOME/master-repo"
docker compose up -d
docker exec -it postgres-postgres-1 psql -U dev -d devdb

docker-compose.yml（master-repo/docker-compose.yml に記載）:
services:
  postgres:
    image: postgres:16-alpine
    env_file: [postgres/.env]
    volumes:
      - ./postgres/data:/var/lib/postgresql/data
      - ./postgres/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports: ["5432:5432"]

postgres/.env:
POSTGRES_USER=dev
POSTGRES_PASSWORD=<変更すること>
POSTGRES_DB=devdb
-->
<!-- [/DISABLED] -->

> PostgreSQL は現在無効。有効化時は Docker Desktop for Mac を起動し上記ブロックを展開すること。

---

## 4. Python 環境セットアップ（Mac）

```zsh
cd ~/master-repo
python3 -m venv .venv
source .venv/bin/activate
pip install -r python3/requirements.txt
```

---

## 5. Git セットアップ（Mac）

### 事前準備: GitHub 認証設定（初回必須）

macOS では **GitHub CLI** による認証が最もシンプル。

```zsh
# GitHub CLI のインストール（未導入の場合）
brew install gh

# 認証（ブラウザが開き GitHub でログイン）
gh auth login
# → GitHub.com → HTTPS → Login with a web browser を選択

# 確認
gh auth status
```

> SSH キーを使う場合は `ssh-keygen -t ed25519` でキー生成後、GitHub の Settings → SSH keys に登録すること。

### ケースA: `~/master-repo` に直接配置（推奨）

```zsh
# リポジトリは作成済みのため clone のみ実行
git clone https://github.com/<YOUR_GITHUB_USERNAME>/master-repo.git ~/master-repo
```

---

### ケースB: iCloud Drive 配下に配置

> パスにスペースが含まれるため、**clone → シンボリックリンク作成 → deploy** の順序を守ること。

```zsh
# 1. 認証完了後、iCloud Drive 配下へ clone
cd "$HOME/Library/Mobile Documents/com~apple~CloudDocs"
git clone https://github.com/<YOUR_GITHUB_USERNAME>/master-repo.git master-repo

# 2. シンボリックリンクを作成（スペースを含むパスを回避）
ln -s "$HOME/Library/Mobile Documents/com~apple~CloudDocs/master-repo" "$HOME/master-repo"

# 3. 確認
ls -la ~/master-repo
```

---

### 日常同期（ケースA・B 共通）

```zsh
gsync   # ~/.zshrc の関数（pull → 差分があれば commit → push）
```

---

## 6. Claude 活用ポリシー（Mac）

Claude は賢く優秀なアシスタントとして活用する。用途に応じて以下のモデルを使い分けること。

| 用途 | モデル | 理由 |
|---|---|---|
| コード生成・調査・要約・日常タスク | **Claude Haiku** | 高速・低コスト。通常作業はこちらを優先 |
| レビュー・欠点確認・設計判断・重要な意思決定 | **Claude Sonnet** | 精度重視。Haiku で不十分な場合に切り替え |

> 迷ったら Haiku で始め、出力の質が不十分であれば Sonnet に切り替える。

---

## 7. Mac 固有の仮定事項

| # | 仮定内容 |
|---|---|
| C1 | リポジトリ配置はケースA（`~/master-repo` 直接）またはケースB（iCloud+シンボリックリンク）から選択 |
| C2 | tmux は Homebrew でインストール済み |
| C3 | Docker Desktop for Mac — PostgreSQL 有効化時に必要 |
| C4 | GitHub CLI (`gh`) または SSH キーによる認証を初回セットアップ時に完了済み |
