@echo off
setlocal
cd /d "%~dp0"

echo =========================================
echo TinyFault-FER Quartus II 13.0 SP1 Compile
echo Target: Cyclone IV E EP4CE22F17C6
echo =========================================
echo.

where quartus_sh >nul 2>&1
if %ERRORLEVEL%==0 (
    set "QSH=quartus_sh"
    goto RUN
)

if exist "C:\altera\13.0sp1\quartus\bin64\quartus_sh.exe" (
    set "QSH=C:\altera\13.0sp1\quartus\bin64\quartus_sh.exe"
    goto RUN
)

if exist "C:\altera\13.0sp1\quartus\bin\quartus_sh.exe" (
    set "QSH=C:\altera\13.0sp1\quartus\bin\quartus_sh.exe"
    goto RUN
)

echo ERROR: quartus_sh.exe was not found.
echo.
echo Open the Quartus II command shell, cd to this folder, and run:
echo     quartus_sh --flow compile tinyfault_mac
echo.
pause
exit /b 1

:RUN
echo Using: %QSH%
echo.
"%QSH%" --flow compile tinyfault_mac
set ERR=%ERRORLEVEL%

echo.
if not "%ERR%"=="0" (
    echo =========================================
    echo COMPILATION FAILED - error code %ERR%
    echo =========================================
    pause
    exit /b %ERR%
)

echo =========================================
echo COMPILATION FINISHED
echo =========================================
echo.
echo Important reports:
echo   output_files\tinyfault_mac.fit.summary
echo   output_files\tinyfault_mac.sta.rpt
echo.
echo ---- FITTER SUMMARY ----
if exist "output_files\tinyfault_mac.fit.summary" (
    type "output_files\tinyfault_mac.fit.summary"
) else (
    echo Fitter summary not found.
)
echo.
echo Search the timing report for "Fmax Summary":
echo   output_files\tinyfault_mac.sta.rpt
echo.
pause
endlocal
