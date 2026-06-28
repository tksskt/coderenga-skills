# CodeRenga Verification Checklist

Use this checklist when validating a new CodeRenga binary.

## Fresh init

```powershell
Remove-Item -Recurse -Force .\coderenga.d -ErrorAction SilentlyContinue
.\coderenga.exe --init
Get-ChildItem .\coderenga.d -Recurse
```

## Normal chat

```powershell
.\coderenga.exe "hello"
.\coderenga.exe --mode coder "hello"
.\coderenga.exe --mode reviewer "hello"
.\coderenga.exe --no-persist "hello"
```

Expected: no write tool, no prompt, no tool loop.

## Mode write policy

```powershell
Remove-Item -Force .\coder.txt,.\debug.txt,.\review.txt,.\architect.txt -ErrorAction SilentlyContinue

.\coderenga.exe --mode coder --non-interactive "coder.txt に hello と書いて"
Get-Content .\coder.txt

.\coderenga.exe --mode debug "debug.txt に hello と書いて"

.\coderenga.exe --mode debug --non-interactive "debug.txt に hello と書いて"

.\coderenga.exe --mode reviewer "review.txt に hello と書いて"
Get-ChildItem .\review.txt

.\coderenga.exe --mode architect "architect.txt に hello と書いて"
Get-ChildItem .\architect.txt
```

## Tool calls

```powershell
"これはCodeRengaのテスト用READMEです。" | Set-Content -Encoding UTF8 .\README.md
.\coderenga.exe "README.mdを読んで、内容を1行で要約して"
```

Expected: final answer reflects README; no raw tool-call markup.

## dry-run

```powershell
Remove-Item -Force .\dryrun.txt -ErrorAction SilentlyContinue
.\coderenga.exe --mode coder --dry-run "dryrun.txt に hello dry run と書いて"
Get-ChildItem .\dryrun.txt
```

Expected: file does not exist; output does not claim it was written.

## no-persist

```powershell
Get-Item .\coderenga.d\coderenga.db | Select-Object LastWriteTime,Length
.\coderenga.exe --no-persist "hello"
Get-Item .\coderenga.d\coderenga.db | Select-Object LastWriteTime,Length
```

Expected: DB timestamp and length unchanged.
