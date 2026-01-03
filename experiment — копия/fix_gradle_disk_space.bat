@echo off
REM Скрипт для исправления ошибки Gradle "Недостаточно места на диске"
chcp 65001 >nul
cd /d "%~dp0"
echo ============================================================
echo ИСПРАВЛЕНИЕ ОШИБКИ GRADLE: НЕДОСТАТОЧНО МЕСТА НА ДИСКЕ
echo ============================================================
echo.

REM Создаем папку для Gradle на диске D если её нет
if not exist "D:\gradle_home" (
    echo [1/3] Создание папки Gradle на диске D...
    mkdir "D:\gradle_home"
    echo ✓ Папка создана: D:\gradle_home
) else (
    echo [1/3] Папка Gradle уже существует: D:\gradle_home
)
echo.

REM Устанавливаем переменные окружения для текущей сессии
echo [2/3] Установка переменной окружения GRADLE_USER_HOME...
set GRADLE_USER_HOME=D:\gradle_home
echo ✓ Переменная окружения установлена
echo   GRADLE_USER_HOME=%GRADLE_USER_HOME%
echo.

REM Очищаем старый кэш Gradle на диске C:
echo [3/3] Очистка старого кэша Gradle на диске C:...
if exist "%USERPROFILE%\.gradle" (
    echo Найден старый кэш Gradle: %USERPROFILE%\.gradle
    echo Остановка Gradle daemon...
    gradle --stop 2>nul
    echo Очистка кэша...
    if exist "%USERPROFILE%\.gradle\caches" (
        rmdir /s /q "%USERPROFILE%\.gradle\caches" 2>nul
        echo ✓ Кэш Gradle очищен
    ) else (
        echo Кэш Gradle не найден
    )
) else (
    echo Старый кэш Gradle не найден
)
echo.

echo ============================================================
echo ✓ ИСПРАВЛЕНИЕ ЗАВЕРШЕНО
echo ============================================================
echo.
echo Теперь Gradle будет использовать диск D: для кэша.
echo.
echo Для глобальной настройки запустите с правами администратора:
echo   setup_gradle_d.ps1
echo.
pause

