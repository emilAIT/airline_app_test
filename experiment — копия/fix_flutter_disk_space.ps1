# Скрипт для исправления ошибки "Недостаточно места на диске" в Flutter
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "ИСПРАВЛЕНИЕ ОШИБКИ FLUTTER: НЕДОСТАТОЧНО МЕСТА НА ДИСКЕ" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Создаем временную папку на диске D если её нет
$tempDir = "D:\flutter_temp"
if (-not (Test-Path $tempDir)) {
    Write-Host "[1/5] Создание временной папки на диске D..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    Write-Host "✓ Папка создана: $tempDir" -ForegroundColor Green
} else {
    Write-Host "[1/5] Временная папка уже существует: $tempDir" -ForegroundColor Green
}
Write-Host ""

# Создаем папку для Gradle на диске D если её нет
$gradleHome = "D:\gradle_home"
if (-not (Test-Path $gradleHome)) {
    Write-Host "[2/5] Создание папки Gradle на диске D..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $gradleHome -Force | Out-Null
    Write-Host "✓ Папка создана: $gradleHome" -ForegroundColor Green
} else {
    Write-Host "[2/5] Папка Gradle уже существует: $gradleHome" -ForegroundColor Green
}
Write-Host ""

# Устанавливаем переменные окружения для текущей сессии
Write-Host "[3/5] Установка переменных окружения для временных файлов..." -ForegroundColor Yellow
$env:TMP = $tempDir
$env:TEMP = $tempDir
$env:TMPDIR = $tempDir
$env:FLUTTER_TMP = $tempDir
$env:GRADLE_USER_HOME = $gradleHome
Write-Host "✓ Переменные окружения установлены" -ForegroundColor Green
Write-Host "  TMP=$env:TMP"
Write-Host "  TEMP=$env:TEMP"
Write-Host "  FLUTTER_TMP=$env:FLUTTER_TMP"
Write-Host "  GRADLE_USER_HOME=$env:GRADLE_USER_HOME"
Write-Host ""

# Переходим в директорию frontend
$frontendDir = Join-Path $PSScriptRoot "frontend"
if (-not (Test-Path $frontendDir)) {
    Write-Host "ОШИБКА: Директория frontend не найдена!" -ForegroundColor Red
    Write-Host "Убедитесь, что скрипт запущен из корня проекта." -ForegroundColor Yellow
    pause
    exit 1
}

Set-Location $frontendDir

# Очищаем Flutter кэш и build артефакты
Write-Host "[4/5] Очистка Flutter кэша и build артефактов..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Очистка Flutter build кэша..." -ForegroundColor Cyan
flutter clean
Write-Host ""

Write-Host "Очистка pub кэша..." -ForegroundColor Cyan
flutter pub cache repair
Write-Host ""

Write-Host "Очистка build директории..." -ForegroundColor Cyan
if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Build директория очищена" -ForegroundColor Green
}
Write-Host ""

Write-Host "Очистка .dart_tool директории..." -ForegroundColor Cyan
if (Test-Path ".dart_tool") {
    Remove-Item -Path ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ .dart_tool директория очищена" -ForegroundColor Green
}
Write-Host ""

# Очищаем временные файлы Flutter на диске C:
Write-Host "[5/5] Очистка временных файлов Flutter на диске C:..." -ForegroundColor Yellow
$flutterTempPath = Join-Path $env:LOCALAPPDATA "Temp"
$flutterToolsDirs = Get-ChildItem -Path $flutterTempPath -Filter "flutter_tools.*" -Directory -ErrorAction SilentlyContinue
if ($flutterToolsDirs) {
    foreach ($dir in $flutterToolsDirs) {
        Write-Host "Удаление: $($dir.FullName)" -ForegroundColor Gray
        Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "✓ Временные файлы Flutter очищены" -ForegroundColor Green
} else {
    Write-Host "Временные файлы Flutter не найдены" -ForegroundColor Gray
}
Write-Host ""

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "✓ ИСПРАВЛЕНИЕ ЗАВЕРШЕНО" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Теперь вы можете запустить Flutter и Gradle команды." -ForegroundColor Green
Write-Host "Временные файлы Flutter: $tempDir" -ForegroundColor Green
Write-Host "Кэш Gradle: $gradleHome" -ForegroundColor Green
Write-Host ""
Write-Host "Для глобальной настройки запустите:" -ForegroundColor Yellow
Write-Host "  frontend\setup_flutter_temp_d.ps1" -ForegroundColor White
Write-Host "  setup_gradle_d.ps1" -ForegroundColor White
Write-Host "  (с правами администратора)" -ForegroundColor Gray
Write-Host ""
Write-Host "Для запуска приложения используйте:" -ForegroundColor Yellow
Write-Host "  start_flutter_frontend.bat" -ForegroundColor White
Write-Host ""
pause

