@echo off
REM Скрипт для очистки Flutter кэша и build артефактов
chcp 65001 >nul
cd /d "%~dp0"
echo ============================================================
echo ОЧИСТКА FLUTTER КЭША И BUILD АРТЕФАКТОВ
echo ============================================================
echo.

REM Переходим в директорию frontend
cd frontend

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
) else (
    echo Build директория не найдена
)
echo.

echo Очистка .dart_tool директории...
if exist ".dart_tool" (
    rmdir /s /q ".dart_tool" 2>nul
    echo ✓ .dart_tool директория очищена
) else (
    echo .dart_tool директория не найдена
)
echo.

echo Очистка временных файлов Flutter на диске C:...
if exist "%LOCALAPPDATA%\Temp\flutter_tools.*" (
    for /d %%i in ("%LOCALAPPDATA%\Temp\flutter_tools.*") do (
        echo Удаление: %%i
        rmdir /s /q "%%i" 2>nul
    )
    echo ✓ Временные файлы Flutter очищены
) else (
    echo Временные файлы Flutter не найдены
)
echo.

echo Очистка кэша Gradle на диске C:...
if exist "%USERPROFILE%\.gradle" (
    echo Остановка Gradle daemon...
    gradle --stop 2>nul
    if exist "%USERPROFILE%\.gradle\caches" (
        rmdir /s /q "%USERPROFILE%\.gradle\caches" 2>nul
        echo ✓ Кэш Gradle очищен
    ) else (
        echo Кэш Gradle не найден
    )
) else (
    echo Кэш Gradle не найден
)
echo.

echo ============================================================
echo ✓ ОЧИСТКА ЗАВЕРШЕНА
echo ============================================================
echo.
pause

