$art = @"
   _____ ________________  ____________   __________  ____  _______   _______ _______________
  / ___// ____/ ____/ __ \/ ____/_  __/  / ____/ __ \/ __ \/ ____/ | / / ___//  _/ ____/ ___/
  \__ \/ __/ / /   / /_/ / __/   / /    / /_  / / / / /_/ / __/ /  |/ /\__ \ / // /    \__ \ 
 ___/ / /___/ /___/ _, _/ /___  / /    / __/ / /_/ / _, _/ /___/ /|  /___/ // // /___ ___/ / 
/____/_____/\____/_/ |_/_____/ /_/    /_/    \____/_/ |_/_____/_/ |_//____/___/\____//____/  
by Stuart, Schulz and Sky.
"@

Write-Host $art -ForegroundColor Cyan

$bar = ""
for ($i = 1; $i -le 14; $i++) {
    $bar += "o"
    $percent = [int](($i / 14) * 100)
    Write-Host ("`r[" + $bar.PadRight(14) + "] " + $percent + "%") -NoNewline -ForegroundColor Green
    Start-Sleep -Milliseconds 140
}
Write-Host ""

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
        
        $result += [PSCustomObject]@{
            ProcessName    = $proc.ProcessName
            PID            = $proc.Id
            StartTime      = $start.ToString("o")
            Elapsed        = ((Get-Date) - $start).ToString()
            ExecutablePath = $path
            User           = $owner
        }
    }
}

$result | Sort-Object StartTime -Descending | ConvertTo-Json -Depth 4
