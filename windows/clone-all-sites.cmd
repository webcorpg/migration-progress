@echo off
setlocal
REM Clone/pull all webcorpg site repos into %%USERPROFILE%%\Projects\<domain>
REM Double-click this file, or run from cmd.
REM Default = Phase 1 only. Examples:
REM   clone-all-sites.cmd -Phase All
REM   clone-all-sites.cmd -Phase 2

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0clone-all-sites.ps1" %*
set ERR=%ERRORLEVEL%
echo.
pause
exit /b %ERR%
