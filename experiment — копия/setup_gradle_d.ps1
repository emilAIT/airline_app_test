# Скрипт для настройки Gradle для использования диска D
# Запустите этот скрипт с правами администратора для глобальной настройки
# Или запустите без прав для настройки только текущей сессии

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "НАСТРОЙКА GRADLE ДЛЯ ИСПОЛЬЗОВАНИЯ ДИСКА D" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Создаем папку для Gradle на диске D
$gradleHome = "D:\gradle_home"
if (-not (Test-Path $gradleHome)) {
    Write-Host "Создание папки Gradle: $gradleHome" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $gradleHome -Force | Out-Null
    Write-Host "Папка создана успешно!" -ForegroundColor Green
} else {
    Write-Host "Папка Gradle уже существует: $gradleHome" -ForegroundColor Green
}

# Проверяем права администратора
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host ""
    Write-Host "Обнаружены права администратора. Устанавливаю переменные окружения глобально..." -ForegroundColor Yellow
    
    # Устанавливаем системные переменные окружения
    [Environment]::SetEnvironmentVariable("GRADLE_USER_HOME", $gradleHome, "Machine")
    
    Write-Host "Переменная окружения GRADLE_USER_HOME установлена глобально!" -ForegroundColor Green
    Write-Host "ПЕРЕЗАГРУЗИТЕ VS CODE ИЛИ КОМАНДНУЮ СТРОКУ для применения изменений" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Права администратора не обнаружены. Устанавливаю переменные для текущей сессии..." -ForegroundColor Yellow
    
    # Устанавливаем переменные для текущей сессии
    $env:GRADLE_USER_HOME = $gradleHome
    
    Write-Host "Переменная установлена для текущей сессии PowerShell!" -ForegroundColor Green
    Write-Host "Для глобальной настройки запустите скрипт с правами администратора" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Текущее значение переменной:" -ForegroundColor Cyan
Write-Host "  GRADLE_USER_HOME: $env:GRADLE_USER_HOME"
Write-Host ""
Write-Host "Готово! Теперь Gradle будет использовать диск D для кэша." -ForegroundColor Green
Write-Host ""

