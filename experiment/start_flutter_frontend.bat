@echo off
REM Этот файл запускает Flutter с временной папкой на диске D
chcp 65001 >nul
cd /d "%~dp0"
echo ============================================================
echo ЗАПУСК FLUTTER FRONTEND
echo ============================================================
echo Текущая директория: %CD%
echo.

REM Создаем временную папку на диске D если её нет
if not exist "D:\flutter_temp" (
    echo Создание временной папки на диске D...
    mkdir "D:\flutter_temp"
)

REM Устанавливаем переменные окружения для временных файлов на диск D
set TMP=D:\flutter_temp
set TEMP=D:\flutter_temp
set TMPDIR=D:\flutter_temp

REM Также устанавливаем для Flutter
set FLUTTER_TMP=D:\flutter_temp

echo Временная папка установлена: D:\flutter_temp
echo.

REM Переходим в директорию frontend
cd frontend

echo Запуск Flutter приложения...
echo ============================================================
echo.

REM Запускаем Flutter
flutter run -d edge

pause



