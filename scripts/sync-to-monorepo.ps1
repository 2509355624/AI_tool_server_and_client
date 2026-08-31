# Mirror sync: export independent repo HEAD into monorepo client/ and server/, then commit+push.
# Usage:
#   .\scripts\sync-to-monorepo.ps1
#   .\scripts\sync-to-monorepo.ps1 -NoPush
#   .\scripts\sync-to-monorepo.ps1 -Only client
#   .\scripts\sync-to-monorepo.ps1 -Only server
param(
    [ValidateSet('all', 'client', 'server')]
    [string]$Only = 'all',
    [switch]$NoPush,
    [switch]$NoCommit
)

$ErrorActionPreference = 'Stop'

$MonoRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot 'sync-config.ps1')

if ([string]::IsNullOrWhiteSpace($ClientDirName) -or [string]::IsNullOrWhiteSpace($ServerDirName)) {
    throw 'ClientDirName/ServerDirName must be set in sync-config.ps1'
}
if ($ClientDirName -in @('.', '..') -or $ServerDirName -in @('.', '..')) {
    throw 'Invalid ClientDirName/ServerDirName'
}

function Assert-GitRepo([string]$Path, [string]$Label) {
    if (-not (Test-Path (Join-Path $Path '.git'))) {
        throw "$Label is not a git repo: $Path (edit scripts\sync-config.ps1)"
    }
}

function Get-RepoMeta([string]$Path) {
    Push-Location $Path
    try {
        $branch = (git rev-parse --abbrev-ref HEAD).Trim()
        $sha = (git rev-parse --short HEAD).Trim()
        $full = (git rev-parse HEAD).Trim()
        $subject = (git log -1 --pretty=%s).Trim()
        $dirty = -not [string]::IsNullOrWhiteSpace((git status --porcelain))
        return [pscustomobject]@{
            Branch  = $branch
            Sha     = $sha
            FullSha = $full
            Subject = $subject
            Dirty   = $dirty
        }
    }
    finally {
        Pop-Location
    }
}

function Assert-SafeDest([string]$DestDir) {
    $dest = [System.IO.Path]::GetFullPath($DestDir).TrimEnd('\')
    $root = $MonoRoot.TrimEnd('\')
    if ($dest -eq $root) {
        throw "Refusing to export into monorepo root: $dest"
    }
    if (-not $dest.StartsWith($root + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Dest outside monorepo: $dest"
    }
    if (Test-Path (Join-Path $dest '.git')) {
        throw "Refusing to clear a path that contains .git: $dest"
    }
}

function Clear-DirKeepRoot([string]$Dir) {
    Assert-SafeDest $Dir
    if (-not (Test-Path $Dir)) {
        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
        return
    }
    Get-ChildItem -LiteralPath $Dir -Force | ForEach-Object {
        Remove-Item -LiteralPath $_.FullName -Recurse -Force
    }
}

function Export-GitHead([string]$RepoPath, [string]$DestDir) {
    Assert-SafeDest $DestDir
    Clear-DirKeepRoot $DestDir
    $name = 'mono_export_' + [guid]::NewGuid().ToString('N') + '.tar'
    $tar = Join-Path $env:TEMP $name
    try {
        Push-Location $RepoPath
        try {
            git archive --format=tar -o $tar HEAD
            if ($LASTEXITCODE -ne 0) { throw "git archive failed: $RepoPath" }
        }
        finally {
            Pop-Location
        }
        tar -xf $tar -C $DestDir
        if ($LASTEXITCODE -ne 0) { throw "tar extract failed -> $DestDir" }
    }
    finally {
        if (Test-Path $tar) { Remove-Item $tar -Force -ErrorAction SilentlyContinue }
    }
}

Assert-GitRepo $ClientRepo 'client'
Assert-GitRepo $ServerRepo 'server'
Assert-GitRepo $MonoRoot 'monorepo'

$clientDest = [System.IO.Path]::GetFullPath((Join-Path $MonoRoot $ClientDirName))
$serverDest = [System.IO.Path]::GetFullPath((Join-Path $MonoRoot $ServerDirName))
$lines = New-Object System.Collections.Generic.List[string]

if ($Only -eq 'all' -or $Only -eq 'client') {
    $meta = Get-RepoMeta $ClientRepo
    if ($meta.Dirty) {
        Write-Warning ("Client has uncommitted changes; mirroring committed HEAD only ({0})" -f $meta.Sha)
    }
    Write-Host (">> export client  {0}@{1} - {2}" -f $meta.Branch, $meta.Sha, $meta.Subject)
    Write-Host ("   -> {0}" -f $clientDest)
    Export-GitHead $ClientRepo $clientDest
    [void]$lines.Add(("client: {0}@{1} - {2}" -f $meta.Branch, $meta.Sha, $meta.Subject))
    [void]$lines.Add(("client_full: {0}" -f $meta.FullSha))
}

if ($Only -eq 'all' -or $Only -eq 'server') {
    $meta = Get-RepoMeta $ServerRepo
    if ($meta.Dirty) {
        Write-Warning ("Server has uncommitted changes; mirroring committed HEAD only ({0})" -f $meta.Sha)
    }
    Write-Host (">> export server  {0}@{1} - {2}" -f $meta.Branch, $meta.Sha, $meta.Subject)
    Write-Host ("   -> {0}" -f $serverDest)
    Export-GitHead $ServerRepo $serverDest
    [void]$lines.Add(("server: {0}@{1} - {2}" -f $meta.Branch, $meta.Sha, $meta.Subject))
    [void]$lines.Add(("server_full: {0}" -f $meta.FullSha))
}

$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$info = @(
    '# Mirror sync stamp (auto-generated)',
    '',
    ("SyncedAt: {0}" -f $stamp),
    ''
) + $lines
$info -join "`n" | Set-Content -Path (Join-Path $MonoRoot 'SYNC_INFO.md') -Encoding UTF8

Push-Location $MonoRoot
try {
    if (-not (Test-Path (Join-Path $MonoRoot '.git'))) {
        throw "Monorepo .git missing at $MonoRoot"
    }
    git add -A
    $pending = git status --porcelain
    if ([string]::IsNullOrWhiteSpace($pending)) {
        Write-Host 'Monorepo already matches independent HEAD; nothing to commit.'
        if (-not $NoPush) {
            git push -u origin HEAD
        }
        return
    }

    if (-not $NoCommit) {
        $summary = ($lines | Where-Object { $_ -notmatch '_full:' }) -join '; '
        $msg = "Sync mirror: $summary"
        git commit -m $msg
        if ($LASTEXITCODE -ne 0) { throw 'monorepo commit failed' }
        Write-Host 'Monorepo commit created.'
    }

    if ((-not $NoPush) -and (-not $NoCommit)) {
        git push -u origin HEAD
        if ($LASTEXITCODE -ne 0) { throw 'monorepo push failed' }
        Write-Host 'Pushed to origin.'
    }
}
finally {
    Pop-Location
}
