function Global:Get-MinerTimeout {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$minerjson
    )

    $miner = $minerjson | ConvertFrom-Json
    $reason = "error"

    if ($Miner.hashrate -eq 0 -or $null -eq $Miner.hashrate) {
        if ($null -eq $miner.xprocess) { $reason = "no start" }
        else {
            if ($Miner.Type -ne "*ASIC*") {
                $MinerProc = Get-Process -Id $miner.xprocess.id -ErrorAction SilentlyContinue
                if ($null -eq $MinerProc) { $reason = "crashed" }
                else { $reason = "no hash" }
            }
            else { $Reason = "no hash" }
        }
    }
    $RejectCheck = Join-Path ".\timeout\warnings" "$($miner.Name)_$($miner.Algo)_rejection.txt"
    if (Test-Path $RejectCheck) { $reason = "rejections" }

    return $reason
}

function Global:Set-Power {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$PwrType,
        [Parameter(Position = 1, Mandatory = $true)]
        [String]$PwrDevices
    )
        $GPUPower = 0
    switch -Wildcard ($PwrType) {
        "*AMD*" { $GPUPower = (Global:Set-AMDStats).watts }
         "*NVIDIA*" { 
            $D = Global:Get-DeviceString -TypeCount $($Global:GCount.NVIDIA.PSObject.Properties.Value.Count) -TypeDevices $PwrDevices
            $Power = (Global:Set-NvidiaStats).watts 
            for($i = 0; $i -lt $D.Count; $i++){
                $DI = $D[$i]
                $GPUPower += $Power[$DI]
            }
            Remove-Variable Power
            Remove-Variable D
            Remove-Variable DI
        }
    }
    $($GPUPower | Measure-Object -Sum).Sum
}

function Global:Get-Intensity {
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [String]$LogMiner,
        [Parameter(Position = 1, Mandatory = $false)]
        [String]$LogAlgo,
        [Parameter(Position = 2, Mandatory = $false)]
        [String]$LogPath
    )

    $LogAlgo = $LogAlgo -replace "`/", "`-"
    $ParseLog = ".\logs\$($LogMiner).log"
    if (Test-Path $ParseLog) {
        $GetInfo = Get-Content $ParseLog
        $GetIntensity = $GetInfo | Select-String "intensity"
        $GetDifficulty = $GetInfo | Select-String "difficulty"
        $NotePath = Split-Path $LogPath
        if ($GetIntensity) { $GetIntensity | Set-Content "$NotePath\$($LogAlgo)_intensity.txt" }
        if ($GetDifficulty) { $GetDifficulty | Set-Content "$NotePath\$($LogAlgo)_difficulty.txt" }
    }
}

function Global:Start-WattOMeter {
    Global:Write-Log "

  Starting Watt-O-Meter
       __________
      |   ____   |
      |  /    \  |
      | | .''. | |
      | |   /  | |
      |==========|
      |   WATT   |
      |__________|
  
        Note: 
  -WattOMeter No Does Not
  Stop Watt Calculations.
  
  `".\config\power.json`" must not have
  any values stored.

  Run clear_watts to remove watt readings.
  " -foregroundcolor yellow
}

function Global:Start-Benchmark {
    $global:BestActiveMiners | ForEach-Object {
        $global:ActiveSymbol += $($_.Symbol)
        $MinerPoolBan = $false
        $MinerAlgoBan = $false
        $MinerBan = $false
        $Global:Strike = $false
        $global:WasBenchmarked = $false
        if ($_.BestMiner -eq $true) {
            $NewName = $_.Algo -replace "`_", "`-"
            $NewName = $NewName -replace "`/", "`-"
            if ($null -eq $_.XProcess -or $_.XProcess.HasExited) {
                $_.Status = "Failed"
                $global:WasBenchmarked = $False
                $Global:Strike = $true
                Global:Write-Log "Cannot Benchmark- Miner is not running" -ForegroundColor Red
            }
            else {
                $_.HashRate = 0
                $global:WasBenchmarked = $False
                $WasActive = [math]::Round(((Get-Date) - $_.XProcess.StartTime).TotalSeconds)
                if ($WasActive -ge $global:MinerStatInt) {
                    Global:Write-Log "$($_.Name) $($_.Symbol) Was Active for $WasActive Seconds"
                    Global:Write-Log "Attempting to record hashrate for $($_.Name) $($_.Symbol)" -foregroundcolor "Cyan"
                    for ($i = 0; $i -lt 4; $i++) {
                        $Miner_HashRates = Global:Get-HashRate -Type $_.Type
                        $_.HashRate = $Miner_HashRates
                        if ($global:WasBenchmarked -eq $False) {
                            $HashRateFilePath = Join-Path ".\stats" "$($_.Name)_$($NewName)_hashrate.txt"
                            $NewHashrateFilePath = Join-Path ".\backup" "$($_.Name)_$($NewName)_hashrate.txt"
                            if (-not (Test-Path "backup")) { New-Item "backup" -ItemType "directory" | Out-Null }
                            Global:Write-Log "$($_.Name) $($_.Symbol) Starting Bench"
                            if ($null -eq $Miner_HashRates -or $Miner_HashRates -eq 0) {
                                $Global:Strike = $true
                                Global:Write-Log "Stat Attempt Yielded 0" -Foregroundcolor Red
                                Start-Sleep -S .25
                                $GPUPower = 0
                                if ($global:Config.Params.WattOMeter -eq "Yes" -and $_.Type -ne "CPU") {
                                    $GetWatts = Get-Content ".\config\power\power.json" | ConvertFrom-Json
                                    if ($GetWatts.$($_.Algo)) {
                                        $GetWatts.$($_.Algo)."$($_.Type)_Watts" = "$GPUPower"
                                        $GetWatts | ConvertTo-Json -Depth 3 | Set-Content ".\config\power\power.json"
                                    }
                                    else {
                                        $WattTypes = @{NVIDIA1_Watts = ""; NVIDIA2_Watts = ""; NVIDIA3_Watts = ""; AMD1_Watts = ""; CPU_Watts = "" }
                                        $GetWatts | Add-Member "$($_.Algo)" $WattTypes
                                        $GetWatts.$($_.Algo)."$($_.Type)_Watts" = "$GPUPower"
                                        $GetWatts | ConvertTo-Json -Depth 3 | Set-Content ".\config\power\power.json"
                                    }
                                }
                            }
                            else {
                                if ($global:Config.Params.WattOMeter -eq "Yes" -and $_.Type -ne "CPU") { try { $GPUPower = Global:Set-Power $($_.Type) $($_.Devices) }catch { Global:Write-Log "WattOMeter Failed"; $GPUPower = 0 } }
                                else { $GPUPower = 1 }
                                if ($global:Config.Params.WattOMeter -eq "Yes" -and $_.Type -ne "CPU") {
                                    $GetWatts = Get-Content ".\config\power\power.json" | ConvertFrom-Json
                                    if ($GetWatts.$($_.Algo)) {
                                        $StatPower = Global:Set-Stat -Name "$($_.Name)_$($NewName)_Watts" -Value $GPUPower
                                        $GetWatts.$($_.Algo)."$($_.Type)_Watts" = "$($StatPower.Day)"
                                        $GetWatts | ConvertTo-Json -Depth 3 | Set-Content ".\config\power\power.json"
                                    }
                                    else {
                                        $StatPower = Global:Set-Stat -Name "$($_.Name)_$($NewName)_Watts" -Value $GPUPower
                                        $WattTypes = @{NVIDIA1_Watts = ""; NVIDIA2_Watts = ""; NVIDIA3_Watts = ""; AMD1_Watts = ""; CPU_Watts = "" }
                                        $GetWatts | Add-Member "$($_.Algo)" $WattTypes
                                        $GetWatts.$($_.Algo)."$($_.Type)_Watts" = "$($StatPower.Day)"
                                        $GetWatts | ConvertTo-Json -Depth 3 | Set-Content ".\config\power\power.json"
                                    }
                                }
                                $Stat = Global:Set-Stat -Name "$($_.Name)_$($NewName)_hashrate" -Value $Miner_HashRates -AsHashRate
                                Start-Sleep -s 1
                                $GetLiveStat = Global:Get-Stat "$($_.Name)_$($NewName)_hashrate"
                                $StatCheck = "$($GetLiveStat.Live)"
                                $ScreenCheck = "$($StatCheck | Global:ConvertTo-Hash)"
                                if ($ScreenCheck -eq "0.00 PH" -or $null -eq $StatCheck) {
                                    $Global:Strike = $true
                                    $global:WasBenchmarked = $False
                                    Global:Write-Log "Stat Failed Write To File" -Foregroundcolor Red
                                }
                                else {
                                    Global:Write-Log "Recorded Hashrate For $($_.Name) $($_.Symbol) Is $($ScreenCheck)" -foregroundcolor "magenta"
                                    if ($global:Config.Params.WattOMeter -eq "Yes") { Global:Write-Log "Watt-O-Meter scored $($_.Name) $($_.Symbol) at $($GPUPower) Watts" -ForegroundColor magenta }
                                    if (-not (Test-Path $NewHashrateFilePath)) {
                                        Copy-Item $HashrateFilePath -Destination $NewHashrateFilePath -force
                                        Global:Write-Log "$($_.Name) $($_.Symbol) Was Benchmarked And Backed Up" -foregroundcolor yellow
                                    }
                                    $global:WasBenchmarked = $True
                                    Global:Get-Intensity $_.Type $_.Symbol $_.Path
                                    Global:Write-Log "Stat Written
" -foregroundcolor green
                                    $Global:Strike = $false
                                } 
                            }
                        }
                    }
                    ##Check For High Rejections
                    $RejectCheck = Join-Path ".\timeout\warnings" "$($_.Name)_$($NewName)_rejection.txt"
                    if (Test-Path $RejectCheck) {
                        Global:Write-Log "Rejections Are Too High" -ForegroundColor DarkRed
                        $global:WasBenchmarked = $false
                        $Global:Strike = $true
                    }
                }
            }

            if ($Global:Strike -ne $true) {
                if ($Global:Warnings."$($_.Name)" -ne $null) { $Global:Warnings."$($_.Name)" | ForEach-Object { try { $_.bad = 0 }catch { } } }
                if ($Global:Warnings."$($_.Name)_$($_.Algo)" -ne $null) { $Global:Warnings."$($_.Name)_$($_.Algo)" | ForEach-Object { try { $_.bad = 0 }catch { } } }
                if ($Global:Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)" -ne $null) { $Global:Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)" | ForEach-Object { try { $_.bad = 0 }catch { } } }
            }
     
            ## Strike-Out System. Will not work with Lite Mode
            if ($global:Config.Params.Lite -eq "No") {
                if ($Global:Strike -eq $true) {
                    if ($global:WasBenchmarked -eq $False) {
                        if (-not (Test-Path ".\timeout")) { New-Item "timeout" -ItemType "directory" | Out-Null }
                        if (-not (Test-Path ".\timeout\pool_block")) { New-Item -Path ".\timeout" -Name "pool_block" -ItemType "directory" | Out-Null }
                        if (-not (Test-Path ".\timeout\algo_block")) { New-Item -Path ".\timeout" -Name "algo_block" -ItemType "directory" | Out-Null }
                        if (-not (Test-Path ".\timeout\miner_block")) { New-Item -Path ".\timeout" -Name "miner_block" -ItemType "directory" | Out-Null }
                        if (-not (Test-Path ".\timeout\warnings")) { New-Item -Path ".\timeout" -Name "warnings" -ItemType "directory" | Out-Null }
                        Start-Sleep -S .25
                        $global:Config.Params.TimeoutFile = Join-Path ".\timeout\warnings" "$($_.Name)_$($NewName)_TIMEOUT.txt"
                        $HashRateFilePath = Join-Path ".\stats" "$($_.Name)_$($NewName)_hashrate.txt"
                        if (-not (Test-Path $global:Config.Params.TimeoutFile)) { "$($_.Name) $($_.Symbol) Hashrate Check Timed Out" | Set-Content ".\timeout\warnings\$($_.Name)_$($NewName)_TIMEOUT.txt" -Force }
                        if ($Global:Warnings."$($_.Name)" -eq $null) { $Global:Warnings += [PSCustomObject]@{"$($_.Name)" = [PSCustomObject]@{bad = 0 } }
                        }
                        if ($Global:Warnings."$($_.Name)_$($_.Algo)" -eq $null) { $Global:Warnings += [PSCustomObject]@{"$($_.Name)_$($_.Algo)" = [PSCustomObject]@{bad = 0 } }
                        }
                        if ($Global:Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)" -eq $null) { $Global:Warnings += [PSCustomObject]@{"$($_.Name)_$($_.Algo)_$($_.MinerPool)" = [PSCustomObject]@{bad = 0 } }
                        }
                        $Global:Warnings."$($_.Name)" | ForEach-Object { try { $_.bad++ }catch { } }
                        $Global:Warnings."$($_.Name)_$($_.Algo)" | ForEach-Object { try { $_.bad++ }catch { } }
                        $Global:Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)" | ForEach-Object { try { $_.bad++ }catch { } }
                        if ($Global:Warnings."$($_.Name)".bad -ge $global:Config.Params.MinerBanCount) { $MinerBan = $true }
                        if ($Global:Warnings."$($_.Name)_$($_.Algo)".bad -ge $global:Config.Params.AlgoBanCount) { $MinerAlgoBan = $true }
                        if ($Global:Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)".bad -ge $global:Config.Params.PoolBanCount) { $MinerPoolBan = $true }
                        ##Strike One
                        if ($MinerPoolBan -eq $false -and $MinerAlgoBan -eq $false -and $MinerBan -eq $false) {
                            Global:Write-Log "First Strike: There was issue with benchmarking.
" -ForegroundColor DarkRed;
                        }
                        ##Strike Two
                        if ($MinerPoolBan -eq $true) {
                            $minerjson = $_ | ConvertTo-Json -Compress
                            $reason = Global:Get-MinerTimeout $minerjson
                            $HiveMessage = "Ban: $($_.Algo):$($_.Name) From $($_.MinerPool)- $reason "
                            Global:Write-Log "Strike Two: Benchmarking Has Failed - $HiveMessage
" -ForegroundColor DarkRed
                            $NewPoolBlock = @()
                            if (Test-Path ".\timeout\pool_block\pool_block.txt") { $GetPoolBlock = Get-Content ".\timeout\pool_block\pool_block.txt" | ConvertFrom-Json }
                            Start-Sleep -S 1
                            if ($GetPoolBlock) { $GetPoolBlock | ForEach-Object { $NewPoolBlock += $_ } }
                            $NewPoolBlock += $_
                            $NewPoolBlock | ConvertTo-Json | Set-Content ".\timeout\pool_block\pool_block.txt"
                            $Global:Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)" | ForEach-Object { try { $_.bad = 0 }catch { } }
                            $HiveWarning = @{result = @{command = "timeout" } }
                            if ($global:Websites) {
                                $global:Websites | ForEach-Object {
                                    $Sel = $_
                                    try {
                                        Global:Add-Module "$($(v).web)\methods.psm1"
                                        Global:Get-WebModules $Sel
                                        $SendToHive = Global:Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -Website "$($Sel)"
                                    }
                                    catch { Global:Write-Log "WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow } 
                                    Global:Remove-WebModules $sel
                                }
                            }
                            Global:Write-Log "$HiveMessage" -ForegroundColor Red
                            Start-Sleep -S 1
                        }
                        ##Strike Three: He's Outta Here
                        if ($MinerAlgoBan -eq $true) {
                            $minerjson = $_ | ConvertTo-Json -Compress
                            $reason = Global:Get-MinerTimeout $minerjson
                            $HiveMessage = "Ban: $($_.Algo):$($_.Name) from all pools- $reason "
                            Global:Write-Log "Strike three: $HiveMessage
" -ForegroundColor DarkRed
                            $NewAlgoBlock = @()
                            if (Test-Path $HashRateFilePath) { Remove-Item $HashRateFilePath -Force }
                            if (Test-Path ".\timeout\algo_block\algo_block.txt") { $GetAlgoBlock = Get-Content ".\timeout\algo_block\algo_block.txt" | ConvertFrom-Json }
                            Start-Sleep -S 1
                            if ($GetAlgoBlock) { $GetAlgoBlock | ForEach-Object { $NewAlgoBlock += $_ } }
                            $NewAlgoBlock += $_
                            $NewAlgoBlock | ConvertTo-Json | Set-Content ".\timeout\algo_block\algo_block.txt"
                            $Global:Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)" | ForEach-Object { try { $_.bad = 0 }catch { } }
                            $Global:Warnings."$($_.Name)_$($_.Algo)" | ForEach-Object { try { $_.bad = 0 }catch { } }
                            $HiveWarning = @{result = @{command = "timeout" } }
                            if ($global:Websites) {
                                $global:Websites | ForEach-Object {
                                    $Sel = $_
                                    try {
                                        Global:Add-Module "$($(v).web)\methods.psm1"
                                        Global:Get-WebModules $Sel
                                        $SendToHive = Global:Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -Website "$($Sel)"
                                    }
                                    catch { Global:Write-Log "WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow } 
                                    Global:Remove-WebModules $sel
                                }
                            }
                            Global:Write-Log "$HiveMessage" -ForegroundColor Red
                            Start-Sleep -S 1
                        }
                        ##Strike Four: Miner is Finished
                        if ($MinerBan -eq $true) {
                            $HiveMessage = "$($_.Name) sucks, shutting it down."
                            Global:Write-Log "$HiveMessage
" -ForegroundColor DarkRed
                            $NewMinerBlock = @()
                            if (Test-Path $HashRateFilePath) { Remove-Item $HashRateFilePath -Force }
                            if (Test-Path ".\timeout\miner_block\miner_block.txt") { $GetMinerBlock = Get-Content ".\timeout\miner_block\miner_block.txt" | ConvertFrom-Json }
                            Start-Sleep -S 1
                            if ($GetMinerBlock) { $GetMinerBlock | ForEach-Object { $NewMinerBlock += $_ } }
                            $NewMinerBlock += $_
                            $NewMinerBlock | ConvertTo-Json | Set-Content ".\timeout\miner_block\miner_block.txt"
                            $Global:Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)" | ForEach-Object { try { $_.bad = 0 }catch { } }
                            $Global:Warnings."$($_.Name)_$($_.Algo)" | ForEach-Object { try { $_.bad = 0 }catch { } }
                            $Global:Warnings."$($_.Name)" | ForEach-Object { try { $_.bad = 0 }catch { } }
                            $HiveWarning = @{result = @{command = "timeout" } }
                            if ($global:Websites) {
                                $global:Websites | ForEach-Object {
                                    $Sel = $_
                                    try {
                                        Global:Add-Module "$($(v).web)\methods.psm1"
                                        Global:Get-WebModules $Sel
                                        $SendToHive = Global:Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -Website "$($Sel)"
                                    }
                                    catch { Global:Write-Log "WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow } 
                                    Global:Remove-WebModules $sel
                                }
                            }
                            Global:Write-Log "$HiveMessage" -ForegroundColor Red
                            Start-Sleep -S 1
                        }
                    }
                }
            }
        }
    }
}