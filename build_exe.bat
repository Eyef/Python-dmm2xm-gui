@echo off
echo ==========================================
echo Building dmm2xm_gui.exe with Nuitka
echo ==========================================

REM Проверяем наличие Nuitka
pip show nuitka >nul 2>&1
if errorlevel 1 (
    echo Installing Nuitka...
    pip install nuitka
)

REM Устанавливаем компилятор если нужно
where gcc >nul 2>&1
if errorlevel 1 (
    echo Installing MinGW...
    pip install mingw
)

REM Собираем EXE в режиме папки (standalone) с метаданными
nuitka --standalone ^
       --windows-console-mode=disable ^
       --enable-plugin=tk-inter ^
       --include-module=dmm2xm_convert ^
       --include-module=dmm2xm_core ^
       --windows-icon-from-ico=dmm2xm.ico ^
       --company-name="Doom 2D Community" ^
       --product-name="DMM TO XM Converter" ^
       --file-version=1.2.0.0 ^
       --product-version=1.2.0.0 ^
       --file-description="Audio converter for mod, s3m, and xm formats" ^
       --output-dir=build ^
       --output-filename=dmm2xm_gui.exe ^
       dmm2xm_gui.py

if errorlevel 1 (
    echo.
    echo ERROR: Build failed!
    pause
    exit /b 1
)

echo.
echo ==========================================
echo BUILD SUCCESSFUL!
echo Dist folder: build\dmm2xm_gui.dist
echo ==========================================
echo ИНСТРУКЦИЯ: Заархивируйте папку "build\dmm2xm_gui.dist" в ZIP перед отправкой на Google Диск.
pause
