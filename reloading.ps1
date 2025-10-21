$art = @"
   _____ ________________  ____________   __________  ____  _______   _______ _______________
  / ___// ____/ ____/ __ \/ ____/_  __/  / ____/ __ \/ __ \/ ____/ | / / ___//  _/ ____/ ___/
  \__ \/ __/ / /   / /_/ / __/   / /    / /_  / / / / /_/ / __/ /  |/ /\__ \ / // /    \__ \ 
 ___/ / /___/ /___/ _, _/ /___  / /    / __/ / /_/ / _, _/ /___/ /|  /___/ // // /___ ___/ / 
/____/_____/\____/_/ |_/_____/ /_/    /_/    \____/_/ |_/_____/_/ |_//____/___/\____//____/  
"@

$subtitle = "by Stuart, Schulz and Sky."

Clear-Host
Write-Host ""
Write-Host $art -ForegroundColor Cyan
Write-Host $subtitle -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Inicializando análise de processos..." -ForegroundColor Gray
Write-Host ""

$barLength = 50
$bar = ""
for ($i = 1; $i -le $barLength; $i++) {
    $bar += "█"
    $spaces = " " * ($barLength - $i)
    $percent = [int](($i / $barLength) * 100)
    
    $color = "Green"
    if ($percent -ge 75) { $color = "Cyan" }
    elseif ($percent -ge 50) { $color = "Yellow" }
    
    Write-Host ("`r  [" + $bar + $spaces + "] " + $percent.ToString().PadLeft(3) + "%") -NoNewline -ForegroundColor $color
    Start-Sleep -Milliseconds 40
}
Write-Host "`n"

$thresholdMinutes = 60
$threshold = (Get-Date).AddMinutes(-$thresholdMinutes)
$result = @()

Write-Host "  🔍 Coletando informações dos processos..." -ForegroundColor DarkGray
Write-Host ""

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
            StartTime      = $start
            StartTimeFormatted = $start.ToString("dd/MM/yyyy HH:mm:ss")
            Elapsed        = "{0:D2}h {1:D2}m {2:D2}s" -f [int]$elapsed.TotalHours, $elapsed.Minutes, $elapsed.Seconds
            ExecutablePath = if ($path) { $path } else { "N/A" }
            User           = if ($owner) { $owner } else { "Desconhecido" }
        }
    }
}

$divider = "═" * 90
$thinDivider = "─" * 88

Write-Host "  $divider" -ForegroundColor Cyan
Write-Host "  ║" -NoNewline -ForegroundColor Cyan
Write-Host "  📊 PROCESSOS INICIADOS NOS ÚLTIMOS $thresholdMinutes MINUTOS".PadRight(86) -NoNewline -ForegroundColor Yellow
Write-Host "  ║" -ForegroundColor Cyan
Write-Host "  $divider" -ForegroundColor Cyan
Write-Host ""

if ($result.Count -gt 0) {
    $sortedResults = $result | Sort-Object StartTime -Descending
    $counter = 1
    
    foreach ($item in $sortedResults) {
        $boxTop = "  ╔" + ("═" * 86) + "╗"
        $boxBottom = "  ╚" + ("═" * 86) + "╝"
        $boxMid = "  ╟" + ("─" * 86) + "╢"
        
        Write-Host $boxTop -ForegroundColor DarkCyan
        
        Write-Host "  ║ " -NoNewline -ForegroundColor DarkCyan
        Write-Host "#$counter".PadRight(4) -NoNewline -ForegroundColor White
        Write-Host "│ " -NoNewline -ForegroundColor DarkGray
        Write-Host "Processo: " -NoNewline -ForegroundColor White
        Write-Host "$($item.ProcessName)".PadRight(40) -NoNewline -ForegroundColor Green
        Write-Host "│ PID: " -NoNewline -ForegroundColor White
        Write-Host "$($item.PID)".PadRight(15) -NoNewline -ForegroundColor Magenta
        Write-Host "║" -ForegroundColor DarkCyan
        
        Write-Host $boxMid -ForegroundColor DarkCyan
        
        Write-Host "  ║ " -NoNewline -ForegroundColor DarkCyan
        Write-Host "    " -NoNewline
        Write-Host "│ " -NoNewline -ForegroundColor DarkGray
        Write-Host "🕐 Iniciado: " -NoNewline -ForegroundColor White
        Write-Host "$($item.StartTimeFormatted)".PadRight(38) -NoNewline -ForegroundColor Cyan
        Write-Host "│ ⏱️  Tempo: " -NoNewline -ForegroundColor White
        Write-Host "$($item.Elapsed)".PadRight(14) -NoNewline -ForegroundColor Yellow
        Write-Host "║" -ForegroundColor DarkCyan
        
        Write-Host $boxMid -ForegroundColor DarkCyan
        
        Write-Host "  ║ " -NoNewline -ForegroundColor DarkCyan
        Write-Host "    " -NoNewline
        Write-Host "│ " -NoNewline -ForegroundColor DarkGray
        Write-Host "👤 Usuário:  " -NoNewline -ForegroundColor White
        Write-Host "$($item.User)".PadRight(70) -NoNewline -ForegroundColor Yellow
        Write-Host "║" -ForegroundColor DarkCyan
        
        Write-Host $boxMid -ForegroundColor DarkCyan
        
        $pathDisplay = $item.ExecutablePath
        if ($pathDisplay.Length -gt 78) {
            $pathDisplay = "..." + $pathDisplay.Substring($pathDisplay.Length - 75)
        }
        
        Write-Host "  ║ " -NoNewline -ForegroundColor DarkCyan
        Write-Host "    " -NoNewline
        Write-Host "│ " -NoNewline -ForegroundColor DarkGray
        Write-Host "📁 Caminho:  " -NoNewline -ForegroundColor White
        Write-Host $pathDisplay.PadRight(70) -NoNewline -ForegroundColor DarkGray
        Write-Host "║" -ForegroundColor DarkCyan
        
        Write-Host $boxBottom -ForegroundColor DarkCyan
        Write-Host ""
        
        $counter++
    }
    
    Write-Host "  $divider" -ForegroundColor Cyan
    Write-Host "  ║" -NoNewline -ForegroundColor Cyan
    Write-Host "  ✅ Total de processos encontrados: $($result.Count)".PadRight(86) -NoNewline -ForegroundColor Green
    Write-Host "  ║" -ForegroundColor Cyan
    Write-Host "  $divider" -ForegroundColor Cyan
} else {
    Write-Host "  ╔" + ("═" * 86) + "╗" -ForegroundColor Yellow
    Write-Host "  ║" -NoNewline -ForegroundColor Yellow
    Write-Host "  ⚠️  Nenhum processo foi iniciado nos últimos $thresholdMinutes minutos.".PadRight(86) -NoNewline -ForegroundColor Yellow
    Write-Host "  ║" -ForegroundColor Yellow
    Write-Host "  ╚" + ("═" * 86) + "╝" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Análise concluída em " -NoNewline -ForegroundColor DarkGray
Write-Host (Get-Date -Format "dd/MM/yyyy HH:mm:ss") -ForegroundColor Gray
Write-Host ""
