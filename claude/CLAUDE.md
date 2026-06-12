# CLAUDE.md — 共通グローバル設定（全デバイス共通）

> **スコープ**: 全デバイス共通ベース設定
> **最終更新**: 2026-06-11
> **デバイス別設定**: Surface → `CLAUDE.surface.md` / Mac → `CLAUDE.mac.md`

---

## コメントアウト規則

無効化セクションは以下のマーカーで囲む。再有効化時はマーカーを削除する。

```
<!-- [DISABLED: 理由] -->
... 無効化内容 ...
<!-- [/DISABLED] -->
```

現在無効化中の機能:

| 機能 | 状態 | 再有効化条件 |
|---|---|---|
| Gemma3:4b 連携 (Ollama) | **無効** | Ollama 動作確認後 |
| PostgreSQL (Docker) | **無効** | DB 設計確定後 |

---

## 1. デバイス構成と同期先

| デバイス | スペック | ローカルリポジトリパス | 設定ファイル |
|---|---|---|---|
| Surface Laptop 7 | ARM / Windows 11 / 16GB / SSD 512GB | `C:\Users\aregr\master-repo` | `CLAUDE.surface.md` |
| MacBook Air | M5 / macOS / 24GB / SSD 512GB | `~/master-repo`（iCloud Drive または任意パス） | `CLAUDE.mac.md` |
| iPhone / iPad | iOS / iPadOS | — | デフォルト設定のまま使用 |

> iPhone / iPad は Claude モバイルアプリをデフォルト設定で使用する。カスタム設定は不要。

---

## 2. ローカル LLM（Ollama / Surface 専用）

<!-- [DISABLED: Gemma連携 — 動作確認待ち] -->
<!--
### Gemma3:4b 知識同期フロー

Claude 出力
    │
    ▼
knowledge_sync.py (python3/src/)
    │  ・要約・構造化
    │  ・synced_to_gemma: false → true に更新
    ▼
reference/knowledge_base/YYYY-MM-DD_<topic>.md
    └─ Surface: Gemma3:4b へ注入
       Mac    : 閲覧・編集

知識ファイルのメタデータ形式:
---
date: YYYY-MM-DD
source: claude | manual
topic: <トピック名>
tags: [tag1, tag2]
device: surface | mac | all
synced_to_gemma: false
---
-->
<!-- [/DISABLED] -->

現在 Ollama は **Surface 上での手動対話のみ**で使用する。
`CLAUDE.surface.md` セクション2を参照。

---

## 3. リポジトリ構成

```
master-repo/                          # GitHub リポジトリルート（作成済み）
├── python3/                          # Python コード
│   ├── src/                          # ソースコード
│   │   └── dev_session.sh            # Mac tmux 起動スクリプト
│   ├── requirements.txt              # 共通依存パッケージ
│   └── README.md
├── claude/                           # Claude 設定ファイル
│   ├── CLAUDE.md                     # 共通設定（本ファイル）
│   ├── CLAUDE.surface.md             # Surface 専用設定
│   ├── CLAUDE.mac.md                 # Mac 専用設定
│   ├── deploy_claude_config.ps1      # Surface 用配置スクリプト
│   ├── deploy_claude_config.sh       # Mac 用配置スクリプト
│   ├── prompts/                      # プロンプトテンプレート
│   └── README.md
├── postgres/                         # PostgreSQL 関連（現在無効）
│   ├── schema/
│   ├── init.sql
│   └── README.md
├── ollama-gemma3-4b/                  # Ollama 関連（現在無効）
│   ├── models/
│   ├── config/
│   └── README.md
├── docker-compose.yml
├── .gitignore
└── README.md
```

> **GitHub アップロード対象**: `claude/` フォルダ配下の全ファイルを先にリポジトリへプッシュしてから、各デバイスで deploy スクリプトを実行すること。

<!-- [DISABLED: PostgreSQL — DB設計確定待ち] -->
<!--
postgres/
    ├── schema/              # DDL・スキーマ定義
    ├── init.sql             # 初期データ
    ├── migrations/          # マイグレーションファイル
    └── .env                 # DB 認証情報（.gitignore 対象）
-->
<!-- [/DISABLED] -->

---

## 4. デバイス間同期（Surface ↔ Mac）

`master-repo` は GitHub プライベートリポジトリとして**作成済み**。両デバイスから clone して使用する。

```
[GitHub: master-repo (private)] ← 作成済み・MDアップロード後に運用開始
        ↑ git push / pull
        │
 ┌──────┴──────┐
 │             │
Surface        MacBook Air
C:\Users\aregr\  ~/master-repo/
master-repo/
```

### .gitignore

```
.venv/
__pycache__/
*.pyc
postgres/.env
postgres/data/
ollama-gemma3-4b/models/
```

### 日常の同期手順

**Surface（PowerShell）:**
```powershell
gsync   # $PROFILE に定義済みのショートカット（CLAUDE.surface.md セクション3参照）
```

**Mac（Zsh）:**
```zsh
gsync   # ~/.zshrc に定義済みのエイリアス（CLAUDE.mac.md セクション2参照）
```

> **gsync の注意**: 変更がない場合は commit がスキップされ push のみ実行される。コンフリクト発生時は自動停止するため、手動で解消してから再実行すること。

### 初回セットアップ（リポジトリ clone）

> **前提**: GitHub への認証設定（Git Credential Manager または SSH キー）を先に完了させること。
> 設定方法は `CLAUDE.surface.md` セクション6 / `CLAUDE.mac.md` セクション5 を参照。

```powershell
# Surface
cd C:\Users\aregr
git clone https://github.com/<YOUR_GITHUB_USERNAME>/master-repo.git master-repo
```

```zsh
# Mac（ケースA: 直接配置）
git clone https://github.com/<YOUR_GITHUB_USERNAME>/master-repo.git ~/master-repo
```

---

## 5. Python 環境（共通）

```txt
# python3/requirements.txt（現在有効なもののみ記載）
# Gemma連携有効化時: requests>=2.31, python-frontmatter>=1.0 を追記
```

仮想環境の構築手順はデバイス別 MD を参照すること。

| デバイス | 参照先 |
|---|---|
| Surface | `CLAUDE.surface.md` セクション5 |
| Mac | `CLAUDE.mac.md` セクション4 |

---

## 6. Claude への共通指示

### モデル活用ポリシー

Claude は賢く優秀なアシスタントとして活用する。用途に応じて以下のモデルを使い分けること。

| 用途 | モデル | 理由 |
|---|---|---|
| コード生成・調査・要約・日常タスク | **Claude Haiku** | 高速・低コスト。通常作業はこちらを優先 |
| レビュー・欠点確認・設計判断・重要な意思決定 | **Claude Sonnet** | 精度重視。Haiku で不十分な場合に切り替え |

> 迷ったら Haiku で始め、出力の質が不十分であれば Sonnet に切り替える。

### 応答スタイル

- 日本語で応答すること（コードコメントは英語可）
- 曖昧・不足がある場合は**仮定を明示**してから進める
- 未検証コードはその旨を明記する
- 重要な出力・調査結果は `claude/prompts/` への保存を提案する
- Claude が生成したコードは `python3/src/YYYY-MM-DD_<topic>.py` へ保存を提案する

### コーディング規約

| 言語 | スタイル |
|---|---|
| Python | PEP8, Black フォーマット, 型ヒント使用 |
| SQL | 大文字キーワード, スネークケーステーブル名 |
| Markdown | 見出しは `#`〜`###`, テーブルは整形済み |

---

## 7. クイックスタート（初期構築手順）

> **重要**: 各デバイスでの作業開始前に、`claude/` フォルダ配下の全ファイルが GitHub にアップロード済みであることを確認すること。アップロード前に deploy スクリプトを実行すると 404 エラーになる。

**Surface（PowerShell）:**

```
0. GitHub に claude/ フォルダの全ファイルがアップロード済みであることを確認
1. Git 認証設定（CLAUDE.surface.md セクション6参照）
2. git clone でリポジトリを取得（CLAUDE.surface.md セクション6参照）
3. deploy_claude_config.ps1 を実行（GITHUB_USER を事前に書き換えること）
   → C:\Users\aregr\.claude\CLAUDE.md に配置される
4. Python 仮想環境を構築（CLAUDE.surface.md セクション5参照）
--- 以下は有効化後 ---
5. [無効中] Ollama / Gemma 設定
6. [無効中] PostgreSQL / Docker 設定
```

**Mac（Zsh）:**

```
0. GitHub に claude/ フォルダの全ファイルがアップロード済みであることを確認
1. Git 認証設定（CLAUDE.mac.md セクション5参照）
2. git clone でリポジトリを取得（CLAUDE.mac.md セクション5参照）
3. deploy_claude_config.sh を実行（GITHUB_USER を事前に書き換えること）
   → ~/.claude/CLAUDE.md に配置される
4. Python 仮想環境を構築（CLAUDE.mac.md セクション4参照）
--- 以下は有効化後 ---
5. [無効中] PostgreSQL / Docker 設定
```

---

## 8. 共通仮定事項

| # | 仮定内容 |
|---|---|
| A1 | GitHub プライベートリポジトリ名は `master-repo`（作成済み） |
| A2 | Python 仮想環境は `master-repo/.venv/` に配置（.gitignore 対象） |
| A3 | デバイス間同期は GitHub 経由（`gsync` ショートカットで実行） |
| A4 | deploy スクリプト実行前に `<YOUR_GITHUB_USERNAME>` を実際のアカウント名に置き換えること |

---

*デバイス固有の設定は `CLAUDE.surface.md` / `CLAUDE.mac.md` を参照すること。*
