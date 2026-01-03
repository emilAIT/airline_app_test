# Комплексный скрипт для исправления всех проблем с местом на диске
# (Flutter + Gradle)
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "КОМПЛЕКСНОЕ ИСПРАВЛЕНИЕ: FLUTTER + GRADLE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ========== НАСТРОЙКА FLUTTER ==========
Write-Host "--- НАСТРОЙКА FLUTTER ---" -ForegroundColor Yellow
Write-Host ""

# Создаем временную папку на диске D для Flutter
$flutterTempDir = "D:\flutter_temp"
if (-not (Test-Path $flutterTempDir)) {
    Write-Host "[Flutter] Создание временной папки на диске D..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $flutterTempDir -Force | Out-Null
    Write-Host "✓ Папка создана: $flutterTempDir" -ForegroundColor Green
} else {
    Write-Host "[Flutter] Временная папка уже существует: $flutterTempDir" -ForegroundColor Green
}

# Устанавливаем переменные окружения для Flutter
$env:TMP = $flutterTempDir
$env:TEMP = $flutterTempDir
$env:TMPDIR = $flutterTempDir
$env:FLUTTER_TMP = $flutterTempDir
Write-Host "✓ Переменные окружения Flutter установлены" -ForegroundColor Green
Write-Host ""

# ========== НАСТРОЙКА GRADLE ==========
Write-Host "--- НАСТРОЙКА GRADLE ---" -ForegroundColor Yellow
Write-Host ""

# Создаем папку для Gradle на диске D
$gradleHome = "D:\gradle_home"
if (-not (Test-Path $gradleHome)) {
    Write-Host "[Gradle] Создание папки Gradle на диске D..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $gradleHome -Force | Out-Null
    Write-Host "✓ Папка создана: $gradleHome" -ForegroundColor Green
} else {
    Write-Host "[Gradle] Папка Gradle уже существует: $gradleHome" -ForegroundColor Green
}

# Устанавливаем переменную окружения для Gradle
$env:GRADLE_USER_HOME = $gradleHome
Write-Host "✓ Переменная окружения GRADLE_USER_HOME установлена" -ForegroundColor Green
Write-Host ""

# ========== ОЧИСТКА КЭША ==========
Write-Host "--- ОЧИСТКА КЭША ---" -ForegroundColor Yellow
Write-Host ""

# Очистка Flutter кэша
$frontendDir = Join-Path $PSScriptRoot "frontend"
if (Test-Path $frontendDir) {
    Set-Location $frontendDir
    
    Write-Host "[Flutter] Очистка Flutter build кэша..." -ForegroundColor Cyan
    & flutter clean 2>$null
    Write-Host "✓ Flutter clean выполнен" -ForegroundColor Green
    
    Write-Host "[Flutter] Очистка pub кэша..." -ForegroundColor Cyan
    & flutter pub cache repair 2>$null
    Write-Host "✓ Pub cache repair выполнен" -ForegroundColor Green
    
    # Очистка build директорий
    if (Test-Path "build") {
        Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✓ Build директория очищена" -ForegroundColor Green
    }
    
    if (Test-Path ".dart_tool") {
        Remove-Item -Path ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✓ .dart_tool директория очищена" -ForegroundColor Green
    }
    
    Set-Location $PSScriptRoot
} else {
    Write-Host "[Flutter] Директория frontend не найдена, пропускаю очистку Flutter" -ForegroundColor Yellow
}
Write-Host ""

# Очистка временных файлов Flutter на диске C:
$flutterTempPath = Join-Path $env:LOCALAPPDATA "Temp"
$flutterToolsDirs = Get-ChildItem -Path $flutterTempPath -Filter "flutter_tools.*" -Directory -ErrorAction SilentlyContinue
if ($flutterToolsDirs) {
    Write-Host "[Flutter] Очистка временных файлов Flutter на диске C:..." -ForegroundColor Cyan
    foreach ($dir in $flutterToolsDirs) {
        Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "✓ Временные файлы Flutter очищены" -ForegroundColor Green
}
Write-Host ""

# Очистка старого кэша Gradle на диске C:
$oldGradleHome = Join-Path $env:USERPROFILE ".gradle"
if (Test-Path $oldGradleHome) {
    Write-Host "[Gradle] Очистка старого кэша Gradle на диске C:..." -ForegroundColor Cyan
    
    # Останавливаем Gradle daemon
    & gradle --stop 2>$null
    
    try {
        Remove-Item -Path "$oldGradleHome\caches" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✓ Кэш Gradle очищен" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Не удалось полностью очистить кэш Gradle" -ForegroundColor Yellow
        Write-Host "  (возможно, файлы используются - закройте IDE и попробуйте снова)" -ForegroundColor Gray
    }
} else {
    Write-Host "[Gradle] Старый кэш Gradle не найден" -ForegroundColor Gray
}
Write-Host ""

# ========== ИТОГИ ==========
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "✓ ВСЕ ИСПРАВЛЕНИЯ ЗАВЕРШЕНЫ" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Настроенные пути:" -ForegroundColor Cyan
Write-Host "  Flutter Temp: $flutterTempDir" -ForegroundColor White
Write-Host "  Gradle Home:  $gradleHome" -ForegroundColor White
Write-Host ""
Write-Host "Для глобальной настройки запустите с правами администратора:" -ForegroundColor Yellow
Write-Host "  .\frontend\setup_flutter_temp_d.ps1" -ForegroundColor White
Write-Host "  .\setup_gradle_d.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Теперь вы можете запускать Flutter и Gradle команды." -ForegroundColor Green
Write-Host ""
pause

