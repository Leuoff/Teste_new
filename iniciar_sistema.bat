@echo off
setlocal

set "PROJECT_DIR=%~dp0"
cd /d "%PROJECT_DIR%" || (
  echo [ERRO] Nao foi possivel acessar a pasta do projeto:
  echo        "%PROJECT_DIR%"
  exit /b 1
)

if not exist "package.json" (
  echo [ERRO] O arquivo package.json nao foi encontrado em:
  echo        "%PROJECT_DIR%"
  exit /b 1
)

where node.exe >nul 2>&1 || (
  echo [ERRO] Node.js nao foi encontrado no PATH do Windows.
  echo        Instale o Node.js e execute este arquivo novamente.
  exit /b 1
)

where npm.cmd >nul 2>&1 || (
  echo [ERRO] npm.cmd nao foi encontrado no PATH do Windows.
  echo        Reinstale o Node.js com o npm e tente novamente.
  exit /b 1
)

if not exist "node_modules\vite\bin\vite.js" (
  echo [ERRO] As dependencias do projeto nao foram encontradas.
  echo        Abra um Prompt de Comando nesta pasta e execute: npm install
  exit /b 1
)

echo [INFO] Iniciando o Sistema Remoto Hamachi...
echo [INFO] Diretorio: "%PROJECT_DIR%"
echo [INFO] Endereco local: http://localhost:8080
echo [INFO] Para encerrar manualmente, pressione Ctrl+C.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PROJECT_DIR%iniciar_sistema.ps1"
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
  echo.
  echo [ERRO] O sistema foi encerrado com o codigo %EXIT_CODE%.
)

exit /b %EXIT_CODE%
