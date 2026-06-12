param(
    [string]$Branch = "main",
    [switch]$Offline
)

$GitHubUser = "yosshy294-byte"
$GitHubRepo = "master-repo"
$RemoteDir  = "claude"
$claudeDir  = "$env:USERPROFILE\.claude"

$fileMap = [ordered]@{
    "CLAUDE.md"         = "CLAUDE.common.md"
    "CLAUDE.surface.md" = "CLAUDE.surface.md"
    "CLAUDE.mac.md"     = "CLAUDE.mac.md"
}

New-Item -Path $claudeDir -ItemType Directory -Force | Out-Null

function Get-GitHubRawFile {
    param([string]$User, [string]$Repo, [string]$BranchName, [string]$RemotePath)
    $url = "https://raw.githubusercontent.com/$User/$Repo/$BranchName/$RemotePath"
    $headers = @{}
    if ($env:GITHUB_PAT) { $headers["Authorization"] = "Bearer $env:GITHUB_PAT" }
    try {
        $r = Invoke-WebRequest -Uri $url -Headers $headers -UseBasicParsing -ErrorAction Stop
        return $r.Content
    } catch {
        $s = $_.Exception.Response.StatusCode.value__
        if ($s -eq 404) {
            Write-Warning "$RemotePath : 404 パスまたはブランチ名を確認してください"
            Write-Warning "URL: $url"
        } elseif ($s -eq 401 -or $s -eq 403) {
            Write-Warning "$RemotePath : $s 認証エラー。GITHUB_PAT を設定してください"
        } else {
            Write-Warning "$RemotePath : エラー $s"
        }
        return $null
    }
}

Write-Host ""

if ($Offline) {
    foreach ($f in $fileMap.Keys) {
        $src = Join-Path $PSScriptRoot $f
        $dst = Join-Path $claudeDir $fileMap[$f]
        if (Test-Path $src) {
            Copy-Item $src $dst -Force
            Write-Host "[LOCAL] $f -> $dst"
        } else {
            Write-Warning "見つかりません: $src"
        }
    }
} else {
    if ($GitHubUser -eq "YOUR_GITHUB_USERNAME") {
        Write-Host "エラー: GitHubUser を実際のアカウント名に書き換えてください"
        exit 1
    }
    Write-Host "GitHub からダウンロード中..."
    Write-Host "  https://github.com/$GitHubUser/$GitHubRepo / $RemoteDir / $Branch"
    Write-Host ""
    $ok = $true
    foreach ($f in $fileMap.Keys) {
        $rp = "$RemoteDir/$f"
        $c = Get-GitHubRawFile -User $GitHubUser -Repo $GitHubRepo -BranchName $Branch -RemotePath $rp
        if ($null -eq $c) { $ok = $false; continue }
        $dst = Join-Path $claudeDir $fileMap[$f]
        [System.IO.File]::WriteAllText($dst, $c, [System.Text.UTF8Encoding]::new($false))
        Write-Host "  [OK] $rp -> $dst"
    }
    if (-not $ok) { Write-Host "一部失敗しました"; exit 1 }
}

Copy-Item (Join-Path $claudeDir "CLAUDE.surface.md") (Join-Path $claudeDir "CLAUDE.md") -Force

Write-Host ""
Write-Host "完了: $claudeDir"
Write-Host "  CLAUDE.md         : Claude Code 読込設定"
Write-Host "  CLAUDE.surface.md : Surface設定"
Write-Host "  CLAUDE.mac.md     : Mac設定"
Write-Host "  CLAUDE.common.md  : 共通設定"
Write-Host ""