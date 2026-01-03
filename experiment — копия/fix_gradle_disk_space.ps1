# Скрипт для исправления ошибки Gradle "Недостаточно места на диске"
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "ИСПРАВЛЕНИЕ ОШИБКИ GRADLE: НЕДОСТАТОЧНО МЕСТА НА ДИСКЕ" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Создаем папку для Gradle на диске D
$gradleHome = "D:\gradle_home"
if (-not (Test-Path $gradleHome)) {
    Write-Host "[1/3] Создание папки Gradle на диске D..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $gradleHome -Force | Out-Null
    Write-Host "✓ Папка создана: $gradleHome" -ForegroundColor Green
} else {
    Write-Host "[1/3] Папка Gradle уже существует: $gradleHome" -ForegroundColor Green
}
Write-Host ""

# Устанавливаем переменные окружения для текущей сессии
Write-Host "[2/3] Установка переменной окружения GRADLE_USER_HOME..." -ForegroundColor Yellow
$env:GRADLE_USER_HOME = $gradleHome
Write-Host "✓ Переменная окружения установлена" -ForegroundColor Green
Write-Host "  GRADLE_USER_HOME=$env:GRADLE_USER_HOME"
Write-Host ""

# Очищаем старый кэш Gradle на диске C:
Write-Host "[3/3] Очистка старого кэша Gradle на диске C:..." -ForegroundColor Yellow
$oldGradleHome = Join-Path $env:USERPROFILE ".gradle"
if (Test-Path $oldGradleHome) {
    Write-Host "Найден старый кэш Gradle: $oldGradleHome" -ForegroundColor Yellow
    Write-Host "Очистка кэша..." -ForegroundColor Cyan
    
    # Останавливаем Gradle daemon если запущен
    Write-Host "Остановка Gradle daemon..." -ForegroundColor Gray
    & gradle --stop 2>$null
    
    # Удаляем кэш
    try {
        Remove-Item -Path "$oldGradleHome\caches" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✓ Кэш Gradle очищен" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Не удалось полностью очистить кэш (возможно, файлы используются)" -ForegroundColor Yellow
        Write-Host "  Попробуйте закрыть все IDE и запустить скрипт снова" -ForegroundColor Gray
    }
} else {
    Write-Host "Старый кэш Gradle не найден" -ForegroundColor Gray
}
Write-Host ""

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "✓ ИСПРАВЛЕНИЕ ЗАВЕРШЕНО" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Теперь Gradle будет использовать диск D: для кэша." -ForegroundColor Green
Write-Host ""
Write-Host "Для глобальной настройки запустите с правами администратора:" -ForegroundColor Yellow
Write-Host "  .\setup_gradle_d.ps1" -ForegroundColor White
Write-Host ""
pause

