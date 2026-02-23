@echo off
title BatchGuard Home Safe Edition
color 0A
setlocal EnableDelayedExpansion

:: ===== SAFE DATE =====
for /f "tokens=1-3 delims=/" %%a in ("%date%") do (
    set d=%%c%%b%%a
)
for /f "tokens=1-2 delims=:" %%a in ("%time%") do (
    set t=%%a%%b
)

:: ===== CONFIG =====
set QUARANTINE=quarantine
set LOGDIR=logs
set SIGNATURES=signatures.db
set LOGFILE=%LOGDIR%\homesafe_scan_%d%_%t%.log

if not exist "%QUARANTINE%" mkdir "%QUARANTINE%"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

if not exist "%SIGNATURES%" (
    echo signatures.db not found!
    pause
    exit
)

:: ===== MENU =====
:menu
cls
echo ===============================================
echo           BATCHGUARD - HOME SAFE EDITION
echo ===============================================
echo.
echo 1 - Quick Scan (C:\Users)
echo 2 - Custom Scan
echo 3 - EXTREME ANALYSIS MODE - NOT RECOMMENDED IF YOU DON'T KNOW HOW TO USE A PC
echo 4 - Exit
echo.
set /p choice=Select option:

if "%choice%"=="1" set SCANROOT=C:\Users & goto scan
if "%choice%"=="2" set /p SCANROOT=Insert directory path: & goto scan
if "%choice%"=="3" goto extreme
if "%choice%"=="4" exit

goto menu

:: ===== NORMAL SCAN =====
:scan
echo Scan Started >> "%LOGFILE%"

for /r "%SCANROOT%" %%F in (*.exe *.bat *.vbs *.ps1 *.js) do (
    call :checkfile "%%F"
)

echo Scan Completed >> "%LOGFILE%"
echo Scan finished.
pause
goto menu

:: ===== SAFE CHECK =====
:checkfile
set FILE=%~1

:: Skip Windows critical folders
echo %FILE% | findstr /i "C:\Windows C:\Program Files" >nul
if %errorlevel%==0 exit /b

for /f "usebackq delims=" %%S in ("%SIGNATURES%") do (
    findstr /i "%%S" "%FILE%" >nul 2>&1
    if !errorlevel! == 0 (
        echo.
        echo [SUSPICIOUS FILE]
        echo %FILE%
        echo SUSPICIOUS: %FILE% >> "%LOGFILE%"

        certutil -hashfile "%FILE%" SHA256 >> "%LOGFILE%" 2>&1

        set /p confirm=Move to quarantine? (Y/N):
        if /i "!confirm!"=="Y" (
            copy "%FILE%" "%QUARANTINE%" >nul 2>&1
            del "%FILE%" >nul 2>&1
            echo QUARANTINED: %FILE% >> "%LOGFILE%"
        )
    )
)

exit /b

:: ===== EXTREME SAFE MODE =====
:extreme
cls
echo ==========================================================
echo     EXTREME ANALYSIS MODE
echo     NOT RECOMMENDED IF YOU DON'T KNOW HOW TO USE A PC
echo ==========================================================
echo.
echo This will scan entire C:\ drive.
echo No automatic deletion.
echo.
set /p confirm1=Type YES to continue:
if /i not "%confirm1%"=="YES" goto menu

set /p confirm2=Type I UNDERSTAND THE RISK:
if /i not "%confirm2%"=="I UNDERSTAND THE RISK" goto menu

set SCANROOT=C:\

echo EXTREME MODE STARTED >> "%LOGFILE%"

for /r "%SCANROOT%" %%F in (*.*) do (
    call :extremecheck "%%F"
)

echo EXTREME MODE COMPLETED >> "%LOGFILE%"
pause
goto menu

:extremecheck
set FILE=%~1

:: Skip system core
echo %FILE% | findstr /i "C:\Windows\System32" >nul
if %errorlevel%==0 exit /b

certutil -hashfile "%FILE%" SHA256 >> "%LOGFILE%" 2>&1

set score=0
echo %FILE% | findstr /i "temp appdata roaming public programdata" >nul && set /a score+=1
echo %FILE% | findstr /i ".ps1 .vbs .js .exe" >nul && set /a score+=1

if %score% GEQ 2 (
    echo HIGH RISK: %FILE%
    echo HIGH RISK: %FILE% >> "%LOGFILE%"
)

exit /b