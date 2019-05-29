function Get-StatusLite {
    $screen = @()
    $global:Config.Params.Type | ForEach-Object {
        $screen += 
        "
########################
    Group: $($_)
########################
"
        $Table = $Global:Miners | Where-Object TYPE -eq $_ | Sort-Object -Property Profit -Descending
        $statindex = 1

        $Table | ForEach-Object { 

            if ($statindex -eq 1) { $Screen += "# 1 Miner:" }
            else { $Screen += "Postion $($statindex): " }

            $Screen += 
            "        Miner: $($_.Miner)
        Mining: $($_.ScreenName)
        Speed: $($_.HashRates | ForEach-Object {if ($null -ne $_) {"$($_ | ConvertTo-Hash)/s"}else {"Benchmarking"}})
        Profit: $($_.Profit | ForEach-Object {if ($null -ne $_) {"$(($_ * $global:Rates.$($global:Config.Params.Currency)).ToString("N2")) $($global:Config.Params.Currency)/Day"}else {"Bench"}}) 
        Pool: $($_.MinerPool)
        Shares: $($($_.Shares -as [Decimal]).ToString("N3"))
"
        
            $statindex++
        }
        $screen += "
########################
########################

" 
    }
    $screen
}

function Get-PriceMessage {
    $global:BestActiveMiners | % {
        if ($_.Profit_Day -ne "bench") { $ScreenProfit = "$(($_.Profit_Day * $global:Rates.$($global:Config.Params.Currency)).ToString("N2")) $($global:Config.Params.Currency)/Day" } else { $ScreenProfit = "Benchmarking" }
        $ProfitMessage = "Current Daily Profit For $($_.Type): $ScreenProfit"
        $ProfitMessage | Out-File ".\build\txt\minerstats.txt" -Append
        $ProfitMessage | Out-File ".\build\txt\charts.txt" -Append
    }
}


function Get-Commands {
    $GetStatusAlgoBans = ".\timeout\algo_block\algo_block.txt"
    $GetStatusPoolBans = ".\timeout\pool_block\pool_block.txt"
    $GetStatusMinerBans = ".\timeout\miner_block\miner_block.txt"
    $GetStatusDownloadBans = ".\timeout\download_block\download_block.txt"
    if (Test-Path $GetStatusDownloadBans) { $StatusDownloadBans = Get-Content $GetStatusDownloadBans | ConvertFrom-Json }
    else { $StatusDownloadBans = $null }
    if (Test-Path $GetStatusAlgoBans) { $StatusAlgoBans = Get-Content $GetStatusAlgoBans | ConvertFrom-Json }
    else { $StatusAlgoBans = $null }
    if (Test-Path $GetStatusPoolBans) { $StatusPoolBans = Get-Content $GetStatusPoolBans | ConvertFrom-Json }
    else { $StatusPoolBans = $null }
    if (Test-Path $GetStatusMinerBans) { $StatusMinerBans = Get-Content $GetStatusMinerBans | ConvertFrom-Json }
    else { $StatusMinerBans = $null }
    $mcolor = "93"
    $me = [char]27
    $MiningStatus = "$me[${mcolor}mCurrently Mining $($global:bestminers_combo.Algo) Algorithm on $($global:bestminers_combo.MinerPool)${me}[0m"
    $MiningStatus | Out-File ".\build\txt\minerstats.txt" -Append
    $MiningStatus | Out-File ".\build\txt\charts.txt" -Append
    $BanMessage = @()
    $mcolor = "91"
    $me = [char]27
    if ($StatusAlgoBans) { $StatusAlgoBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_.Name) mining $($_.Algo) is banned from all pools${me}[0m" } }
    if ($StatusPoolBans) { $StatusPoolBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_.Name) mining $($_.Algo) is banned from $($_.MinerPool)${me}[0m" } }
    if ($StatusMinerBans) { $StatusMinerBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_.Name) is banned${me}[0m" } }
    if ($StatusDownloadBans) { $StatusDownloadBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_.Name) is banned: Download Failed${me}[0m" } }
    if ($GetDLBans) { $GetDLBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_) failed to download${me}[0m" } }
    if ($ConserveMessage) { $ConserveMessage | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_)${me}[0m" } }
    $BanMessage | Out-File ".\build\txt\minerstats.txt" -Append
    $BanMessage | Out-File ".\build\txt\charts.txt" -Append
    $StatusLite = Get-StatusLite
    $StatusDate = Get-Date
    $StatusDate | Out-File ".\build\txt\minerstatslite.txt"
    $StatusLite | Out-File ".\build\txt\minerstatslite.txt" -Append
    $MiningStatus | Out-File ".\build\txt\minerstatslite.txt" -Append
    $BanMessage | Out-File ".\build\txt\minerstatslite.txt" -Append
    $MiningStatus | Out-File ".\build\txt\minerstatslite.txt" -Append
}

function Get-Logo {
    Write-Log '
                                                                        (                    (      *     
                                                                         )\ ) (  (      (     )\ ) (  `    
                                                                         (()/( )\))(     )\   (()/( )\))(   
                                                                          /(_)|(_)()\ |(((_)(  /(_)|(_)()\  
                                                                         (_)) _(())\_)()\ _ )\(_)) (_()((_) 
                                                                         / __|\ \((_)/ (_)_\(_) _ \|  \/  | 
                                                                         \__ \ \ \/\/ / / _ \ |   /| |\/| | 
                                                                         |___/  \_/\_/ /_/ \_\|_|_\|_|  |_| 
                                                                                                          ' -foregroundcolor "DarkRed"
    Write-Log '                                                           sudo apt-get lambo
                                                                                 
                                                                                 
                                                                                 
                                                                                 ' -foregroundcolor "Yellow"
}

function Update-Logging {
    if ($global:LogNum -eq 12) {
        Remove-Item ".\logs\*miner*" -Force -ErrorAction SilentlyContinue
        Remove-Item ".\logs\*crash_report*" -Force -Recurse -ErrorAction SilentlyContinue
        $global:LogNum = 0
    }
    if ($global:logtimer.Elapsed.TotalSeconds -ge 3600) {
        Start-Sleep -S 3
        if (Test-Path ".\logs\*active*") {
            $OldActiveFile = Get-ChildItem ".\logs" | Where BaseName -like "*active*"
            $OldActiveFile | ForEach-Object {
                $RenameActive = $_.fullname -replace ("-active", "")
                if (Test-Path $RenameActive) { Remove-Item $RenameActive -Force }
                Rename-Item $_.FullName -NewName $RenameActive -force
            }
        }
        $GLobal:LogNum++
        $global:logname = ".\logs\miner$($global:LogNum)-active.log"
        $LogTimer.Restart()
    }
}

function Get-MinerActive {
    $ActiveMinerPrograms | Sort-Object -Descending Status,
    { if ($null -eq $_.XProcess) { [DateTime]0 }else { $_.XProcess.StartTime }
    } | Select-Object -First (1 + 6 + 6) | Format-Table -Wrap -GroupBy Status (
        @{Label = "Name"; Expression = { "$($_.Name)" } },
        @{Label = "Active"; Expression = { "{0:dd} Days {0:hh} Hours {0:mm} Minutes" -f $(if ($null -eq $_.XProcess) { $_.Active }else { if ($_.XProcess.HasExited) { ($_.Active) }else { ($_.Active + ((Get-Date) - $_.XProcess.StartTime)) } }) } },
        @{Label = "Launched"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_ Times" } } } },
        @{Label = "Command"; Expression = { "$($_.MinerName) $($_.Devices) $($_.Arguments)" } }
    )
}
