@echo off
setlocal

set "INSTALL_SCRIPT=%~dp0instalar_inicializacao_automatica.ps1"
if not exist "%INSTALL_SCRIPT%" (
  echo [ERRO] O instalador PowerShell nao foi encontrado:
  echo        "%INSTALL_SCRIPT%"
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%INSTALL_SCRIPT%" %*
set "EXIT_CODE=%ERRORLEVEL%"
echo.
pause
exit /b %EXIT_CODE%
