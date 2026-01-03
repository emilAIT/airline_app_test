# Скрипт для запуска backend
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

Write-Host "Starting AIT Airlines Backend..." -ForegroundColor Green
Write-Host ""

.\venv\Scripts\uvicorn.exe app.main:app --host 0.0.0.0 --port 8001 --reload --log-level info





