$ErrorActionPreference = 'Stop'

try {
    Set-Location -LiteralPath $PSScriptRoot
    $vitePath = Join-Path $PSScriptRoot 'node_modules\vite\bin\vite.js'
    if (-not (Test-Path -LiteralPath $vitePath -PathType Leaf)) {
        throw 'Dependencias ausentes. Execute npm install na pasta do projeto.'
    }

    $nodePath = (Get-Command node.exe -ErrorAction Stop).Source
    $listeners = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()
    if ($listeners | Where-Object { $_.Port -eq 8080 }) {
        throw 'A porta 8080 ja esta ocupada. O sistema nao sera iniciado em outra porta.'
    }

    $logDirectory = Join-Path $PSScriptRoot '.remote-access'
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    $logPath = Join-Path $logDirectory 'server.log'

    Write-Host '[INFO] Iniciando o sistema na porta TCP 8080.'
    Write-Host '[INFO] Endereco local: http://localhost:8080'
    Write-Host ('[INFO] Log: {0}' -f $logPath)
    Write-Host '[INFO] Para encerrar manualmente, pressione Ctrl+C.'

    # Native stderr can contain warnings; preserve them without stopping Node.
    $ErrorActionPreference = 'Continue'
    & $nodePath $vitePath --host 0.0.0.0 --port 8080 --strictPort 2>&1 |
        Tee-Object -FilePath $logPath
    $serverExitCode = $LASTEXITCODE
    if ($serverExitCode -ne 0) {
        Write-Host ('[ERRO] O servidor encerrou com codigo {0}. Consulte {1}.' -f $serverExitCode, $logPath)
    }
    exit $serverExitCode
} catch {
    Write-Host ('[ERRO] {0}' -f $_.Exception.Message)
    exit 1
}
