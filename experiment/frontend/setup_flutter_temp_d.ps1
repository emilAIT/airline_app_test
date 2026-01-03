# Скрипт для настройки Flutter временной папки на диск D
# Запустите этот скрипт с правами администратора для глобальной настройки
# Или запустите без прав для настройки только текущей сессии

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "НАСТРОЙКА FLUTTER ДЛЯ ИСПОЛЬЗОВАНИЯ ДИСКА D" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Создаем временную папку на диске D
$tempDir = "D:\flutter_temp"
if (-not (Test-Path $tempDir)) {
    Write-Host "Создание временной папки: $tempDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    Write-Host "Папка создана успешно!" -ForegroundColor Green
} else {
    Write-Host "Временная папка уже существует: $tempDir" -ForegroundColor Green
}

# Проверяем права администратора
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host ""
    Write-Host "Обнаружены права администратора. Устанавливаю переменные окружения глобально..." -ForegroundColor Yellow
    
    # Устанавливаем системные переменные окружения
    [Environment]::SetEnvironmentVariable("TMP", $tempDir, "Machine")
    [Environment]::SetEnvironmentVariable("TEMP", $tempDir, "Machine")
    [Environment]::SetEnvironmentVariable("TMPDIR", $tempDir, "Machine")
    [Environment]::SetEnvironmentVariable("FLUTTER_TMP", $tempDir, "Machine")
    
    Write-Host "Переменные окружения установлены глобально!" -ForegroundColor Green
    Write-Host "ПЕРЕЗАГРУЗИТЕ VS CODE ИЛИ КОМАНДНУЮ СТРОКУ для применения изменений" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Права администратора не обнаружены. Устанавливаю переменные для текущей сессии..." -ForegroundColor Yellow
    
    # Устанавливаем переменные для текущей сессии
    $env:TMP = $tempDir
    $env:TEMP = $tempDir
    $env:TMPDIR = $tempDir
    $env:FLUTTER_TMP = $tempDir
    
    Write-Host "Переменные установлены для текущей сессии PowerShell!" -ForegroundColor Green
    Write-Host "Для глобальной настройки запустите скрипт с правами администратора" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Текущие значения переменных:" -ForegroundColor Cyan
Write-Host "  TMP: $env:TMP"
Write-Host "  TEMP: $env:TEMP"
Write-Host "  TMPDIR: $env:TMPDIR"
Write-Host "  FLUTTER_TMP: $env:FLUTTER_TMP"
Write-Host ""
Write-Host "Готово! Теперь Flutter будет использовать диск D для временных файлов." -ForegroundColor Green


