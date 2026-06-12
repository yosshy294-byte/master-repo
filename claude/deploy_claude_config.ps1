param(
    [string]$Branch = "main",
    [switch]$Offline
)

# =====================================================================
# 設定: 自分のGitHubアカウント名に書き換えること
# =====================================================================
$GitHubUser = "yosshy294-byte"
$GitHubRepo = "master-repo"
$RemoteDir  = "claude"
# =====================================================================

$claudeDir = "$env:USERPROFILE\.claude"

$fileMap = [ordered]@{
    "CLAUDE.md"         = "CLAUDE.common.md"
    "CLAUDE.surface.md" = "CLAUDE.surface.md"
    "CLAUDE.mac.md"     = "CLAUDE.mac.md"
}

New-Item -Path $claudeDir -ItemType Directory -Force | Out-Null

function Get-GitHubRawFile {
    param(
        [string]$User,
        [string]$Repo,
        [string]$BranchName,
        [string]$RemotePath
    )

    $url = "https://raw.githubusercontent.com/$User/$Repo/$BranchName/$RemotePath"

    $headers = @{}
    if ($env:GITHUB_PAT) {
        $headers["Authorization"] = "Bearer $env:GITHUB_PAT"
    }

    try {
        $response = Invoke-WebRequest -Uri $url -Headers $headers -UseBasicParsing -ErrorAction Stop
        return $response.Content
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        if ($status -eq 404) {
            Write-Warning "[$RemotePath] 404: パスまたはブランチ名を確認してください"
            Write-Warning "URL: $url"
        } elseif ($status -eq 401 -or $status -eq 403) {
            Write-Warning "[$RemotePath] ${status}: GITHUB_PAT が必要です"
            Write-Warning "設定例: $env:GITHUB_PAT = 'ghp_xxxxxxxxxxxx'"
        } else {
            Write-Warning "[$RemotePath] エラー: $_"
        }
        return $null
    }
}

Write-Host ""

if ($Offline) {
    Write-Host "オフラインモード: ローカルファイルを使用します。"
    Write-Host ""

    $missing = $false
    foreach ($fileName in $fileMap.Keys) {
        $src = Join-Path $PSScriptRoot $fileName
        if (-not (Test-Path $src)) {
            Write-Warning "ファイルが見つかりません: $src"
            $missing = $true
        }
    }
    if ($missing) {
        Write-Host "スクリプトと同じフォルダに各MDファイルを置いてください。"
        exit 1
    }

    foreach ($fileName in $fileMap.Keys) {
        $dest = Join-Path $claudeDir $fileMap[$fileName]
        Copy-Item (Join-Path $PSScriptRoot $fileName) $dest -Force
        Write-Host "  [LOCAL] $fileName -> $dest"
    }

} else {
    if ($GitHubUser -eq "YOUR_GITHUB_USERNAME") {
        Write-Host "エラー: スクリプト冒頭の GitHubUser を設定してください。"
        exit 1
    }

    Write-Host "GitHub からダウンロード中..."
    Write-Host "  リポジトリ: https://github.com/$GitHubUser/$GitHubRepo"
    Write-Host "  フォルダ  : $RemoteDir/"
    Write-Host "  ブランチ  : $Branch"
    if ($env:GITHUB_PAT) {
        Write-Host "  認証      : GITHUB_PAT 使用"
    }
    Write-Host ""

    $allSuccess = $true

    foreach ($fileName in $fileMap.Keys) {
        $remotePath = "$RemoteDir/$fileName"
        $content = Get-GitHubRawFile -User $GitHubUser -Repo $GitHubRepo -BranchName $Branch -RemotePath $remotePath
        if ($null -eq $content) {
            $allSuccess = $false
            continue
        }
        $dest = Join-Path $claudeDir $fileMap[$fileName]
        [System.IO.File]::WriteAllText($dest, $content, [System.Text.UTF8Encoding]::new($false))
        Write-Host "  [OK] $remotePath -> $dest"
    }

    if (-not $allSuccess) {
        Write-Host ""
        Write-Host "一部ファイルの取得に失敗しました。"
        exit 1
    }
}

# Surface 用アクティブ設定を CLAUDE.md として配置
$surfaceSrc = Join-Path $claudeDir "CLAUDE.surface.md"
$activeDest = Join-Path $claudeDir "CLAUDE.md"
Copy-Item $surfaceSrc $activeDest -Force

Write-Host ""
Write-Host "完了:"
Write-Host "  $claudeDir\CLAUDE.md         (Surface用 / Claude Codeが読込)"
Write-Host "  $claudeDir\CLAUDE.surface.md (Surface設定 参照用)"
Write-Host "  $claudeDir\CLAUDE.mac.md     (Mac設定 参照用)"
Write-Host "  $claudeDir\CLAUDE.common.md  (共通設定 参照用)"
Write-Host ""
Write-Host "確認コマンド:"
Write-Host "  Get-Content $claudeDir\CLAUDE.md | Select-Object -First 5"
Write-Host ""

# プライベートリポジトリの場合:
# $env:GITHUB_PAT = "ghp_xxxxxxxxxxxx"
# .\deploy_claude_config.ps1