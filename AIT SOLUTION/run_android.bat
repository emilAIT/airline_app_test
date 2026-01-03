@echo off
chcp 65001 >nul
echo ========================================
echo   AIT Airlines - Android Setup
echo ========================================
echo.

echo [1/3] Starting Backend Server...
cd /d "%~dp0"
start "Backend Server" cmd /k "chcp 65001 >nul && cd backend && start_backend.bat"
echo Waiting for backend to start...
timeout /t 8 /nobreak >nul

echo.
echo [2/3] Checking Flutter devices...
cd mobile_app
flutter devices
echo.

echo [3/3] Starting Flutter App on Android...
echo.
echo NOTE: Make sure Android emulator is running!
echo.
flutter run -d emulator-5554
pause


