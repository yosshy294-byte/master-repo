# deploy_claude_config.ps1
# GitHub の master-repo/claude/ から CLAUDE 設定ファイルを取得して配置するスクリプト
#
# リポジトリ構成:
#   master-repo/
#   └── claude/
#       ├── CLAUDE.md           <- 共通設定
#       ├── CLAUDE.surface.md   <- Surface 専用設定
#       └── CLAUDE.mac.md       <- Mac 専用設定
#
# 使い方:
#   .\deploy_claude_config.ps1                    # GitHub main ブランチから取得（通常はこれ）
#   .\deploy_claude_config.ps1 -Branch develop    # ブランチ指定
#   .\deploy_claude_config.ps1 -Offline           # ローカルファイルのみ使用（ネット不要）
#
# 事前準備:
#   以下 2 変数を自分の情報に書き換えること

param(
    [string]$Branch = "main",
    [switch]$Offline
)

# =====================================================================
# ★ 設定: 自分のリポジトリ情報に書き換えること
# =====================================================================
$GitHubUser = "yosshy294-byte"   # 例: "yoshinobu"
$GitHubRepo = "master-repo"            # リポジトリ名
$RemoteDir  = "claude"                 # リポジトリ内のフォルダパス
# =====================================================================

$claudeDir = "$env:USERPROFILE\.claude"

# リモートファイル名 → ローカル保存名
$fileMap = [ordered]@{
    "CLAUDE.md"         = "CLAUDE.common.md"   # 共通設定（参照用）
    "CLAUDE.surface.md" = "CLAUDE.surface.md"  # Surface 設定（参照用）
    "CLAUDE.mac.md"     = "CLAUDE.mac.md"      # Mac 設定（参照用）
}

# .claude ディレクトリを作成
New-Item -Path $claudeDir -ItemType Directory -Force | Out-Null

# -----------------------------------------------------------------
# ダウンロード関数
# -----------------------------------------------------------------
function Get-GitHubRawFile {
    param(
        [string]$User,
        [string]$Repo,
        [string]$BranchName,
        [string]$RemotePath   # フォルダ込みのパス例: "claude/CLAUDE.md"
    )

    $url = "https://raw.githubusercontent.com/$User/$Repo/$BranchName/$RemotePath"

    # プライベートリポジトリ対応: 環境変数 GITHUB_PAT が設定されていれば Bearer 認証を付与
    $headers = @{}
    if ($env:GITHUB_PAT) {
        $headers["Authorization"] = "Bearer $env:GITHUB_PAT"
    }

    try {
        $response = Invoke-WebRequest -Uri $url -Headers $headers -UseBasicParsing -ErrorAction Stop
        return $response.Content
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        switch ($status) {
            404 {
                Write-Warning "[$RemotePath] 取得失敗 (404): パス・ブランチ名を確認してください"
                Write-Warning "  URL: $url"
            }
            { $_ -in 401, 403 } {
                Write-Warning "[$RemotePath] 取得失敗 ($status): プライベートリポジトリは GITHUB_PAT が必要です"
                Write-Warning "  設定例: `$env:GITHUB_PAT = 'ghp_xxxxxxxxxxxx'"
            }
            default {
                Write-Warning "[$RemotePath] 取得失敗: $_"
            }
        }
        return $null
    }
}

# -----------------------------------------------------------------
# メイン処理
# -----------------------------------------------------------------
Write-Host ""

if ($Offline) {
    # ---- ローカルモード ----
    Write-Host "オフラインモード: ローカルファイルを使用します。" -ForegroundColor Yellow
    Write-Host ""

    $missing = $false
    foreach ($fileName in $fileMap.Keys) {
        $src = Join-Path $PSScriptRoot $fileName
        if (-not (Test-Path $src)) {
            Write-Warning "ローカルファイルが見つかりません: $src"
            $missing = $true
        }
    }
    if ($missing) {
        Write-Host "スクリプトと同じフォルダに CLAUDE.md / CLAUDE.surface.md / CLAUDE.mac.md を置いてください。" -ForegroundColor Red
        exit 1
    }

    foreach ($fileName in $fileMap.Keys) {
        $dest = Join-Path $claudeDir $fileMap[$fileName]
        Copy-Item (Join-Path $PSScriptRoot $fileName) $dest -Force
        Write-Host "  [ローカル] $fileName → $dest"
    }

} else {
    # ---- GitHub モード ----
    if ($GitHubUser -eq "YOUR_GITHUB_USERNAME") {
        Write-Host "エラー: スクリプト冒頭の `$GitHubUser を設定してください。" -ForegroundColor Red
        exit 1
    }

    Write-Host "GitHub からダウンロード中..." -ForegroundColor Cyan
    Write-Host "  リポジトリ : https://github.com/$GitHubUser/$GitHubRepo"
    Write-Host "  フォルダ   : $RemoteDir/"
    Write-Host "  ブランチ   : $Branch"
    if ($env:GITHUB_PAT) {
        Write-Host "  認証       : GITHUB_PAT 使用（プライベートリポジトリ）" -ForegroundColor Yellow
    }
    Write-Host ""

    $allSuccess = $true

    foreach ($fileName in $fileMap.Keys) {
        $remotePath = "$RemoteDir/$fileName"   # 例: claude/CLAUDE.surface.md
        $content = Get-GitHubRawFile -User $GitHubUser -Repo $GitHubRepo -BranchName $Branch -RemotePath $remotePath
        if ($null -eq $content) {
            $allSuccess = $false
            continue
        }
        $dest = Join-Path $claudeDir $fileMap[$fileName]
        # UTF-8 BOM なしで保存（Claude Code が BOM を誤読するケースを避ける）
        [System.IO.File]::WriteAllText($dest, $content, [System.Text.UTF8Encoding]::new($false))
        Write-Host "  [OK] $remotePath → $dest" -ForegroundColor Green
    }

    if (-not $allSuccess) {
        Write-Host ""
        Write-Host "一部ファイルの取得に失敗しました。上記の警告を確認してください。" -ForegroundColor Red
        exit 1
    }
}

# Surface 用アクティブ設定を CLAUDE.md として配置
# （Claude Code は $env:USERPROFILE\.claude\CLAUDE.md を読み込む）
$surfaceSrc = Join-Path $claudeDir "CLAUDE.surface.md"
$activeDest = Join-Path $claudeDir "CLAUDE.md"
Copy-Item $surfaceSrc $activeDest -Force

# -----------------------------------------------------------------
# 結果表示
# -----------------------------------------------------------------
Write-Host ""
Write-Host "配置完了:" -ForegroundColor Green
Write-Host "  $claudeDir\CLAUDE.md          <- Surface 用アクティブ設定（Claude Code が読込）"
Write-Host "  $claudeDir\CLAUDE.surface.md  <- Surface 設定（参照用）"
Write-Host "  $claudeDir\CLAUDE.mac.md      <- Mac 設定（Mac セットアップ時にコピー）"
Write-Host "  $claudeDir\CLAUDE.common.md   <- 共通設定（参照用）"
Write-Host ""
Write-Host "次のステップ: OneDrive workspace フォルダを作成してください（CLAUDE.md セクション7参照）" -ForegroundColor Cyan
Write-Host ""

# =================================================================
# プライベートリポジトリの場合
# =================================================================
# PAT（Personal Access Token）を環境変数にセットしてから実行してください。
# スクリプトにトークンを直書きしないこと。
#
# 【セッション内のみ有効】
#   $env:GITHUB_PAT = "ghp_xxxxxxxxxxxx"
#   .\deploy_claude_config.ps1
#
# 【永続化（ユーザー環境変数）】
#   [System.Environment]::SetEnvironmentVariable("GITHUB_PAT", "ghp_xxx", "User")
#   # 設定後は PowerShell を再起動してから実行
#
# PAT 発行: GitHub → Settings → Developer settings
#           → Personal access tokens → Fine-grained tokens
#           必要なスコープ: Contents (read)
# =================================================================