# Installs CodeRenga from the latest GitHub Release and initializes coderenga.d.
# Usage examples:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\.cursor\skills\coderenga\scripts\install-coderenga.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\.cursor\skills\coderenga\scripts\install-coderenga.ps1 -Repo tksskt/CodeRenga -InstallDir .\.local\bin -InitDir .
param(
  [string]$Repo = "tksskt/CodeRenga",
  [string]$InstallDir = ".\.local\bin",
  [string]$InitDir = "."
)

$ErrorActionPreference = "Stop"

function Say($msg) { Write-Host "[coderenga-install] $msg" }

function Get-PlatformAsset($assets) {
  $os = "windows|win"
  $arch = if ([Environment]::Is64BitOperatingSystem) { "amd64|x64|x86_64" } else { "386|x86" }
  $patterns = @(
    "coderenga.*($os).*($arch).*\.(zip|tar\.gz|tgz|exe)$",
    "coderenga.*($arch).*($os).*\.(zip|tar\.gz|tgz|exe)$",
    "coderenga.*\.(zip|exe)$"
  )
  foreach ($pattern in $patterns) {
    $hit = $assets | Where-Object { $_.name -match $pattern } | Select-Object -First 1
    if ($hit) { return $hit }
  }
  return $null
}

function Resolve-ExistingCoderenga($installDirFull) {
  $cmd = Get-Command coderenga.exe -ErrorAction SilentlyContinue
  if (-not $cmd) { $cmd = Get-Command coderenga -ErrorAction SilentlyContinue }
  if ($cmd) { return $cmd.Source }

  $localExe = Join-Path $installDirFull "coderenga.exe"
  if (Test-Path $localExe) { return $localExe }

  $localBin = Join-Path $installDirFull "coderenga"
  if (Test-Path $localBin) { return $localBin }

  return $null
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
$installDirFull = (Resolve-Path $InstallDir).Path
$cmdPath = Resolve-ExistingCoderenga $installDirFull

if (-not $cmdPath) {
  Say "coderenga not found. Fetching latest release from https://github.com/$Repo/releases/latest"
  $api = "https://api.github.com/repos/$Repo/releases/latest"
  try {
    $release = Invoke-RestMethod -Uri $api -Headers @{ "User-Agent" = "coderenga-skill-installer" }
  } catch {
    throw "No latest GitHub Release was found for $Repo. Create a release with a CodeRenga binary asset, then rerun this installer. Original error: $($_.Exception.Message)"
  }

  if (-not $release.assets -or $release.assets.Count -eq 0) {
    throw "Latest release '$($release.tag_name)' has no assets. Attach a Windows CodeRenga binary/archive and rerun."
  }

  $asset = Get-PlatformAsset $release.assets
  if (-not $asset) {
    $names = ($release.assets | ForEach-Object { $_.name }) -join ", "
    throw "No suitable Windows CodeRenga asset found in release '$($release.tag_name)'. Assets: $names"
  }

  $tmp = Join-Path $env:TEMP ("coderenga-" + [Guid]::NewGuid().ToString())
  New-Item -ItemType Directory -Force -Path $tmp | Out-Null
  $download = Join-Path $tmp $asset.name
  Say "Downloading $($asset.name)"
  Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $download -Headers @{ "User-Agent" = "coderenga-skill-installer" }

  if ($asset.name -match "\.zip$") {
    Expand-Archive -Path $download -DestinationPath $tmp -Force
    $bin = Get-ChildItem -Path $tmp -Recurse -File | Where-Object { $_.Name -in @("coderenga.exe", "coderenga") } | Select-Object -First 1
    if (-not $bin) { throw "Archive did not contain coderenga.exe or coderenga." }
    Copy-Item $bin.FullName (Join-Path $installDirFull "coderenga.exe") -Force
  } elseif ($asset.name -match "\.(tar\.gz|tgz)$") {
    tar -xzf $download -C $tmp
    $bin = Get-ChildItem -Path $tmp -Recurse -File | Where-Object { $_.Name -in @("coderenga.exe", "coderenga") } | Select-Object -First 1
    if (-not $bin) { throw "Archive did not contain coderenga.exe or coderenga." }
    Copy-Item $bin.FullName (Join-Path $installDirFull "coderenga.exe") -Force
  } elseif ($asset.name -match "\.exe$") {
    Copy-Item $download (Join-Path $installDirFull "coderenga.exe") -Force
  } else {
    throw "Unsupported asset type: $($asset.name)"
  }

  $cmdPath = Join-Path $installDirFull "coderenga.exe"
} else {
  Say "Found existing CodeRenga: $cmdPath"
}

Say "Initializing CodeRenga under $InitDir"
Push-Location $InitDir
try {
  & $cmdPath --init
} finally {
  Pop-Location
}
Say "Done. Try: `"$cmdPath`" --cwd . --mode reviewer `"inspect this repository`""
