@echo off
setlocal
REM Clone/pull all webcorpg site repos into %%USERPROFILE%%\Projects\<domain>
REM Double-click this file, or run from cmd.

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0clone-all-sites.ps1" %*
set ERR=%ERRORLEVEL%
echo.
pause
exit /b %ERR%
