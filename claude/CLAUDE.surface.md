# CLAUDE.surface.md — Surface Laptop 7 専用設定

> **デバイス**: Surface Laptop 7 (ARM / Windows 11 / 16GB RAM / SSD 512GB)
> **リポジトリパス**: `C:\Users\aregr\master-repo`
> **Claude 設定ファイル**: `C:\Users\aregr\master-repo\claude\`
> **リモート**: GitHub `master-repo` (private / 作成済み)
> **共通設定**: `CLAUDE.md` を必ず併せて参照すること
> **最終更新**: 2026-06-11

---

## 1. パス構成

| 用途 | パス |
|---|---|
| リポジトリルート | `C:\Users\aregr\master-repo` |
| Claude 設定ファイル（本ファイル等） | `C:\Users\aregr\master-repo\claude\` |
| Claude Code グローバル設定（自動配置） | `C:\Users\aregr\.claude\CLAUDE.md` |
| Python ソース | `C:\Users\aregr\master-repo\python3\src\` |
| 仮想環境 | `C:\Users\aregr\master-repo\.venv\` |

### deploy_claude_config.ps1 について

`master-repo/claude/` の MD ファイルを `C:\Users\aregr\.claude\` へ取得・配置するスクリプト。

> **⚠️ 実行前の必須手順**
> 1. GitHub に `claude/` フォルダの全ファイルがアップロード済みであること
> 2. スクリプト冒頭の `$GitHubUser` を自分の GitHub アカウント名に書き換えること

```powershell
# 1. スクリプトを編集して GITHUB_USER を設定
notepad C:\Users\aregr\master-repo\claude\deploy_claude_config.ps1
# $GitHubUser = "YOUR_GITHUB_USERNAME"  ← 実際のアカウント名に変更

# 2. 実行
cd C:\Users\aregr\master-repo\claude
.\deploy_claude_config.ps1

# 3. 配置確認
Get-Content C:\Users\aregr\.claude\CLAUDE.md | Select-Object -First 5
```

---

## 2. Ollama（手動対話モード）

> Gemma 連携は現在無効。Ollama は手動対話のみで使用する。
> 有効化手順は `CLAUDE.md` セクション2のコメントアウトブロックを参照。

### 起動・状態確認

```powershell
# 稼働確認（二重起動防止）
$svc = Get-Service -Name "ollama" -ErrorAction SilentlyContinue
if ($svc -and $svc.Status -eq "Running") {
    Write-Host "Ollama 起動中"
} else {
    Start-Service ollama -ErrorAction SilentlyContinue
    if (-not $?) {
        Start-Process ollama -ArgumentList "serve" -WindowStyle Hidden
    }
}

ollama list
ollama run gemma3:4b
```

---

## 3. CLI 設定（Surface）

### VS Code

```jsonc
// .vscode/settings.json
{
  "terminal.integrated.defaultProfile.windows": "PowerShell",
  "terminal.integrated.profiles.windows": {
    "PowerShell": { "source": "PowerShell", "args": ["-NoLogo"] }
  },
  "python.defaultInterpreterPath": "${workspaceFolder}\\.venv\\Scripts\\python.exe",
  "editor.formatOnSave": true,
  "files.eol": "\n",
  "files.encoding": "utf8"
}
```

### PowerShell profile（`$PROFILE` に追記）

> **仮定 B1**: PowerShell 7 (pwsh) を使用。未導入の場合: `winget install Microsoft.PowerShell`

```powershell
# リポジトリルートへ移動
function repo { Set-Location "C:\Users\aregr\master-repo" }

# Claude 設定フォルダへ移動
function claudedir { Set-Location "C:\Users\aregr\master-repo\claude" }

# Python 仮想環境 activate
function venv { & "C:\Users\aregr\master-repo\.venv\Scripts\Activate.ps1" }

# Git 同期ショートカット（変更なし時は commit をスキップ）
function gsync {
    Push-Location "C:\Users\aregr\master-repo"
    git pull
    git add .
    $status = git status --porcelain
    if ($status) {
        git commit -m "sync: $(Get-Date -Format 'yyyy-MM-dd')"
    }
    git push
    Pop-Location
}

# Ollama 手動問い合わせ
function Ask-Gemma {
    param([string]$Prompt, [string]$Context = "")
    $body = @{ model = "gemma3:4b"; prompt = $Prompt; stream = $false }
    if ($Context) { $body.system = $Context }
    $res = Invoke-RestMethod `
        -Uri "http://localhost:11434/api/generate" `
        -Method Post `
        -Body ($body | ConvertTo-Json) `
        -ContentType "application/json; charset=utf-8"
    $res.response
}
Set-Alias gemma Ask-Gemma
# 使用例: gemma "Pythonでファイル一覧を取得するには？"
```

---

## 4. PostgreSQL

<!-- [DISABLED: PostgreSQL — DB設計確定待ち] -->
<!--
cd C:\Users\aregr\master-repo
docker compose up -d
docker exec -it postgres-postgres-1 psql -U dev -d devdb

docker-compose.yml（master-repo/docker-compose.yml に記載）:
services:
  postgres:
    image: postgres:16-alpine
    platform: linux/arm64
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

> PostgreSQL は現在無効。有効化時は Docker Desktop (ARM) を起動し上記ブロックを展開すること。

---

## 5. Python 環境セットアップ（Surface）

### 実行ポリシーの確認（初回必須）

```powershell
Get-ExecutionPolicy
# Restricted の場合:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 仮想環境構築

```powershell
cd C:\Users\aregr\master-repo
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r python3\requirements.txt
```

---

## 6. Git セットアップ（Surface）

### 事前準備: GitHub 認証設定（初回必須）

Windows では **Git Credential Manager (GCM)** が推奨。Git for Windows に同梱されており、初回 clone / push 時にブラウザで認証するだけで以降は自動認証される。

```powershell
# GCM の動作確認
git config --global credential.helper
# → manager または manager-core と表示されれば設定済み

# 未設定の場合（Git for Windows 再インストールで解決することが多い）
git config --global credential.helper manager
```

> PAT（Personal Access Token）を使う場合は GitHub → Settings → Developer settings → Fine-grained tokens で発行し、clone URL に埋め込まずに GCM に登録すること。

### 初回: リポジトリを clone

```powershell
# リポジトリは作成済みのため clone のみ実行
cd C:\Users\aregr
git clone https://github.com/<YOUR_GITHUB_USERNAME>/master-repo.git master-repo
```

### 日常同期

```powershell
gsync   # $PROFILE の関数（pull → 差分があれば commit → push）
```

> **コンフリクト発生時**: gsync が途中で止まる。`git status` で競合ファイルを確認し手動解消後、`gsync` を再実行すること。

---

## 7. Claude 活用ポリシー（Surface）

Claude は賢く優秀なアシスタントとして活用する。用途に応じて以下のモデルを使い分けること。

| 用途 | モデル | 理由 |
|---|---|---|
| コード生成・調査・要約・日常タスク | **Claude Haiku** | 高速・低コスト。通常作業はこちらを優先 |
| レビュー・欠点確認・設計判断・重要な意思決定 | **Claude Sonnet** | 精度重視。Haiku で不十分な場合に切り替え |

> 迷ったら Haiku で始め、出力の質が不十分であれば Sonnet に切り替える。

---

## 8. Surface 固有の仮定事項

| # | 仮定内容 |
|---|---|
| B1 | PowerShell 7 (pwsh) を使用 |
| B2 | リポジトリパスは `C:\Users\aregr\master-repo`（ユーザー名 `aregr` で固定） |
| B3 | Ollama は Windows ARM ネイティブ版をインストール済み |
| B4 | Docker Desktop for Windows (ARM 対応版) — PostgreSQL 有効化時に必要 |
| B5 | Git for Windows インストール済み（GCM 同梱） |
