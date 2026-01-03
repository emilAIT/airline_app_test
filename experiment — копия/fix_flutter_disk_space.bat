@echo off
REM Скрипт для исправления ошибки "Недостаточно места на диске" в Flutter
chcp 65001 >nul
cd /d "%~dp0"
echo ============================================================
echo ИСПРАВЛЕНИЕ ОШИБКИ FLUTTER: НЕДОСТАТОЧНО МЕСТА НА ДИСКЕ
echo ============================================================
echo.

REM Создаем временную папку на диске D если её нет
if not exist "D:\flutter_temp" (
    echo [1/4] Создание временной папки на диске D...
    mkdir "D:\flutter_temp"
    echo ✓ Папка создана: D:\flutter_temp
) else (
    echo [1/4] Временная папка уже существует: D:\flutter_temp
)
echo.

REM Создаем папку для Gradle на диске D если её нет
if not exist "D:\gradle_home" (
    echo [2/4] Создание папки Gradle на диске D...
    mkdir "D:\gradle_home"
    echo ✓ Папка создана: D:\gradle_home
) else (
    echo [2/4] Папка Gradle уже существует: D:\gradle_home
)
echo.

REM Устанавливаем переменные окружения для текущей сессии
echo [3/4] Установка переменных окружения для временных файлов...
set TMP=D:\flutter_temp
set TEMP=D:\flutter_temp
set TMPDIR=D:\flutter_temp
set FLUTTER_TMP=D:\flutter_temp
set GRADLE_USER_HOME=D:\gradle_home
echo ✓ Переменные окружения установлены
echo   TMP=%TMP%
echo   TEMP=%TEMP%
echo   FLUTTER_TMP=%FLUTTER_TMP%
echo   GRADLE_USER_HOME=%GRADLE_USER_HOME%
echo.

REM Переходим в директорию frontend
cd frontend

REM Очищаем Flutter кэш и build артефакты
echo [4/4] Очистка Flutter кэша и build артефактов...
echo.

echo Очистка Flutter build кэша...
call flutter clean
echo.

echo Очистка pub кэша...
call flutter pub cache repair
echo.

echo Очистка build директории...
if exist "build" (
    rmdir /s /q "build" 2>nul
    echo ✓ Build директория очищена
)
echo.

echo Очистка .dart_tool директории...
if exist ".dart_tool" (
    rmdir /s /q ".dart_tool" 2>nul
    echo ✓ .dart_tool директория очищена
)
echo.

echo ============================================================
echo ✓ ИСПРАВЛЕНИЕ ЗАВЕРШЕНО
echo ============================================================
echo.
echo Теперь вы можете запустить Flutter и Gradle команды.
echo Временные файлы Flutter: D:\flutter_temp
echo Кэш Gradle: D:\gradle_home
echo.
echo Для глобальной настройки запустите:
echo   frontend\setup_flutter_temp_d.ps1
echo   setup_gradle_d.ps1
echo   (с правами администратора)
echo.
echo Для запуска приложения используйте:
echo   start_flutter_frontend.bat
echo.
pause

