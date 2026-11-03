[CmdletBinding()]
param(
    [switch]$SomenteTarefa
)

$ErrorActionPreference = 'Stop'
$taskName = 'Sistema Remoto Hamachi'
$firewallRule = 'Sistema Remoto - Porta 8080'
$systemPort = 8080
$projectDir = $PSScriptRoot
$startScript = Join-Path $projectDir 'iniciar_sistema.ps1'
$supportDir = Join-Path $projectDir '.remote-access'
$backupFile = Join-Path $supportDir 'task-before.xml'

try {
    if (-not (Test-Path -LiteralPath $startScript -PathType Leaf)) {
        throw "O arquivo iniciar_sistema.ps1 nao foi encontrado em $projectDir."
    }
    if (-not (Test-Path -LiteralPath (Join-Path $projectDir 'package.json') -PathType Leaf)) {
        throw "O arquivo package.json nao foi encontrado em $projectDir."
    }

    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $windowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    $isAdministrator = $windowsPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $SomenteTarefa -and -not $isAdministrator) {
        throw 'Execute o instalador como Administrador para configurar o Firewall. Se a regra ja estiver correta, use -SomenteTarefa para atualizar apenas a tarefa.'
    }

    Write-Host "[INFO] Configurando a tarefa: $taskName"
    $existingTask = Get-ScheduledTask -TaskPath '\' | Where-Object { $_.TaskName -eq $taskName }
    if ($existingTask) {
        New-Item -ItemType Directory -Path $supportDir -Force | Out-Null
        Export-ScheduledTask -InputObject $existingTask | Set-Content -LiteralPath $backupFile -Encoding Unicode
        Write-Host "[INFO] Copia da tarefa anterior: $backupFile"
    }

    $taskArguments = '-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}"' -f $startScript
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $taskArguments -WorkingDirectory $projectDir
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $identity.Name
    $principal = New-ScheduledTaskPrincipal -UserId $identity.Name -LogonType Interactive -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -StartWhenAvailable `
        -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
        -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
    Register-ScheduledTask -TaskName $taskName -TaskPath '\' -Action $action -Trigger $trigger `
        -Principal $principal -Settings $settings -Description 'Inicia o sistema web na rede Hamachi.' -Force | Out-Null

    if ($SomenteTarefa) {
        Write-Host '[INFO] Modo SomenteTarefa: configuracao do Firewall preservada.'
    }
    else {
        Write-Host "[INFO] Verificando a regra de Firewall para TCP $systemPort..."
        $rules = @(Get-NetFirewallRule -PolicyStore PersistentStore | Where-Object { $_.DisplayName -eq $firewallRule })
        if ($rules.Count -eq 0) {
            New-NetFirewallRule -Name 'ProteticoLAB-Remote-8080' -DisplayName $firewallRule `
                -Direction Inbound -Action Allow -Enabled True -Protocol TCP -LocalPort $systemPort -Profile Any | Out-Null
        }
        else {
            foreach ($rule in $rules) {
                $portFilter = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $rule
                $hasCorrectPort = @($portFilter.LocalPort).Count -eq 1 -and [string]$portFilter.LocalPort -eq [string]$systemPort
                $hasCorrectProtocol = [string]$portFilter.Protocol -in @('TCP', '6')
                if ([string]$rule.Enabled -ne 'True' -or [string]$rule.Direction -ne 'Inbound' -or `
                    [string]$rule.Action -ne 'Allow' -or -not $hasCorrectPort -or -not $hasCorrectProtocol) {
                    Set-NetFirewallRule -InputObject $rule -Enabled True -Direction Inbound -Action Allow `
                        -Protocol TCP -LocalPort $systemPort | Out-Null
                }
            }
        }
        Write-Host "[OK] Firewall: $firewallRule (TCP $systemPort)."
    }

    $listeners = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()
    $portInUse = @($listeners | Where-Object { $_.Port -eq $systemPort }).Count -gt 0
    if ($portInUse) {
        Write-Host "[INFO] A porta $systemPort ja esta em uso. Nenhum segundo servidor foi iniciado."
        Write-Host "[INFO] Confirme o sistema em http://localhost:$systemPort."
    }
    else {
        Start-ScheduledTask -TaskName $taskName -TaskPath '\'
        Write-Host '[INFO] Inicializacao solicitada ao Agendador de Tarefas.'
        Write-Host "[INFO] Confirme o sistema em http://localhost:$systemPort."
    }

    Write-Host "[OK] Tarefa configurada para o logon de $($identity.Name)."
    Write-Host "[INFO] Log do servidor: $(Join-Path $supportDir 'server.log')"
    exit 0
}
catch {
    Write-Host "[ERRO] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host '[INFO] Se a atualizacao da tarefa foi negada, execute o instalador como Administrador.'
    exit 1
}
