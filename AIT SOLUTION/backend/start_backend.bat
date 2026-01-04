@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo Starting AIT Airlines Backend...
echo.
set PYTHONIOENCODING=utf-8
.\venv\Scripts\uvicorn.exe app.main:app --host 0.0.0.0 --port 8000 --reload --log-level info
pause


