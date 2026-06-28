param(
    [string]$RepoRoot = (Get-Location).Path
)

$skillSource = Resolve-Path (Join-Path $PSScriptRoot "..")
$target = Join-Path $RepoRoot ".agents\skills\coderenga-worker"

New-Item -ItemType Directory -Force $target | Out-Null
Copy-Item -Recurse -Force (Join-Path $skillSource "*") $target

Write-Host "Installed CodeRenga Worker skill to $target"
Write-Host "Restart Codex if the skill does not appear."
