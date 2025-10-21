$art = @"
   _____ ________________  ____________   __________  ____  _______   _______ _______________
  / ___// ____/ ____/ __ \/ ____/_  __/  / ____/ __ \/ __ \/ ____/ | / / ___//  _/ ____/ ___/
  \__ \/ __/ / /   / /_/ / __/   / /    / /_  / / / / /_/ / __/ /  |/ /\__ \ / // /    \__ \ 
 ___/ / /___/ /___/ _, _/ /___  / /    / __/ / /_/ / _, _/ /___/ /|  /___/ // // /___ ___/ / 
/____/_____/\____/_/ |_/_____/ /_/    /_/    \____/_/ |_/_____/_/ |_//____/___/\____//____/  
by Stuart, Schulz and Sky.
"@

Write-Host $art -ForegroundColor Cyan
Write-Host ""

$barLength = 50
$bar = ""
for ($i = 1; $i -le $barLength; $i++) {
    $bar += "█"
    $percent = [int](($i / $barLength) * 100)
    Write-Host ("`r[" + $bar.PadRight($barLength) + "] " + $percent + "%") -NoNewline -ForegroundColor Green
    Start-Sleep -Milliseconds 40
}
Write-Host "`n"

$thresholdMinutes = 60
$threshold = (Get-Date).AddMinutes(-$thresholdMinutes)
$result = @()

Get-Process | ForEach-Object {
    $proc = $_
    try {
        $start = $proc.StartTime
    } catch {
        return
    }
    
    if ($null -ne $start -and $start -ge $threshold) {
        $path = $null
        $owner = $null
        
        try {
            $w = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction Stop
            $path = $w.ExecutablePath
            $ownerObj = Invoke-CimMethod -InputObject $w -MethodName GetOwner
            if ($ownerObj.ReturnValue -eq 0) {
                $owner = ($ownerObj.Domain + "\" + $ownerObj.User).Trim("\")
            }
        } catch {}
        
        $elapsed = (Get-Date) - $start
        
        $result += [PSCustomObject]@{
            ProcessName    = $proc.ProcessName
            PID            = $proc.Id
            StartTime      = $start.ToString("dd/MM/yyyy HH:mm:ss")
            Elapsed        = "{0:D2}h {1:D2}m {2:D2}s" -f [int]$elapsed.TotalHours, $elapsed.Minutes, $elapsed.Seconds
            ExecutablePath = $path
            User           = $owner
        }
    }
}

Write-Host "═══════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " PROCESSOS INICIADOS NOS ÚLTIMOS $thresholdMinutes MINUTOS" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

if ($result.Count -gt 0) {
    $result | Sort-Object StartTime -Descending | ForEach-Object {
        Write-Host "┌─────────────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
        Write-Host "│ " -NoNewline -ForegroundColor DarkCyan
        Write-Host "Processo: " -NoNewline -ForegroundColor White
        Write-Host "$($_.ProcessName)" -NoNewline -ForegroundColor Green
        Write-Host " (PID: $($_.PID))" -ForegroundColor Gray
        Write-Host "│ " -NoNewline -ForegroundColor DarkCyan
        Write-Host "Iniciado: " -NoNewline -ForegroundColor White
        Write-Host "$($_.StartTime)" -NoNewline -ForegroundColor Cyan
        Write-Host " | Tempo: " -NoNewline -ForegroundColor White
        Write-Host "$($_.Elapsed)" -ForegroundColor Magenta
        Write-Host "│ " -NoNewline -ForegroundColor DarkCyan
        Write-Host "Usuário:  " -NoNewline -ForegroundColor White
        Write-Host "$($_.User)" -ForegroundColor Yellow
        Write-Host "│ " -NoNewline -ForegroundColor DarkCyan
        Write-Host "Caminho:  " -NoNewline -ForegroundColor White
        Write-Host "$($_.ExecutablePath)" -ForegroundColor DarkGray
        Write-Host "└─────────────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan
        Write-Host ""
    }
    
    Write-Host "═══════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " Total de processos encontrados: $($result.Count)" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
} else {
    Write-Host "Nenhum processo foi iniciado nos últimos $thresholdMinutes minutos." -ForegroundColor Yellow
}

Write-Host ""
