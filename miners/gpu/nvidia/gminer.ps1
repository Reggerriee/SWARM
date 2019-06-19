$(vars).NVIDIATypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "NVIDIA", ""

    ##Miner Path Information
    if ($Global:nvidia.gminer.$ConfigType) { $Path = "$($Global:nvidia.gminer.$ConfigType)" }
    else { $Path = "None" }
    if ($Global:nvidia.gminer.uri) { $Uri = "$($Global:nvidia.gminer.uri)" }
    else { $Uri = "None" }
    if ($Global:nvidia.gminer.minername) { $MinerName = "$($Global:nvidia.gminer.minername)" }
    else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "gminer-$Num"; $Port = "4600$Num"

    Switch ($Num) {
        1 { $Get_Devices = $(vars).NVIDIADevices1; $Rig = $(arg).RigName1 }
        2 { $Get_Devices = $(vars).NVIDIADevices2; $Rig = $(arg).RigName2 }
        3 { $Get_Devices = $(vars).NVIDIADevices3; $Rig = $(arg).RigName3 }
    }

    ##Log Directory
    $Log = Join-Path $($(vars).dir) "logs\$ConfigType.log"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") {
        $GPUDevices1 = $Get_Devices
        $GPUDevices1 = $GPUDevices1 -replace ',', ' '
        $Devices = $GPUDevices1
    }
    else { $Devices = $Get_Devices }    

    ##gminer apparently doesn't know how to tell the difference between
    ##cuda and amd devices, like every other miner that exists. So now I 
    ##have to spend an hour and parse devices
    ##to matching platforms.
    
    $ArgDevices = $Null
    if ($Get_Devices -ne "none") {
        $GPUEDevices = $Get_Devices
        $GPUEDevices = $GPUEDevices -split ","
        $GPUEDevices | ForEach-Object { $ArgDevices += "$($(vars).GCount.NVIDIA.$_) " }
        $ArgDevices = $ArgDevices.Substring(0, $ArgDevices.Length - 1)
    }
    else { $(vars).GCount.NVIDIA.PSObject.Properties.Name | ForEach-Object { $ArgDevices += "$($(vars).GCount.NVIDIA.$_) " }; $ArgDevices = $ArgDevices.Substring(0, $ArgDevices.Length - 1) }

    ##Get Configuration File
    $MinerConfig = $Global:config.miners.gminer

    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = Join-Path $($(vars).dir) "build\export"

    ##Prestart actions before miner launch
    $BE = "/usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0"
    $Prestart = @()
    $PreStart += "export LD_LIBRARY_PATH=$ExportDir"
    $MinerConfig.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

    if ($Global:Coins -eq $true) { $Pools = $global:CoinPools }else { $Pools = $global:AlgoPools }

    ##Build Miner Settings
    $MinerConfig.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

        $MinerAlgo = $_

        if ($MinerAlgo -in $(vars).Algorithm -and $Name -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and $ConfigType -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and $Name -notin $(vars).BanHammer) {
            $StatAlgo = $MinerAlgo -replace "`_", "`-"
            $Stat = Global:Get-Stat -Name "$($Name)_$($StatAlgo)_hashrate" 
            $Check = $Global:Miner_HashTable | Where Miner -eq $Name | Where Algo -eq $MinerAlgo | Where Type -Eq $ConfigType

            if ($Check.RAW -ne "Bad") {
                $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
                    $SelAlgo = $_.Algorithm
                    switch ($SelAlgo) {
                        "equihash_150/5" { $AddArgs = "--algo 150_5 --pers auto " }
                        "cuckoo_cycle" { $AddArgs = "--algo aeternity " }
                        "cuckaroo29" { $AddArgs = "--algo grin29 " }
                        "cuckatoo31" { $AddArgs = "--algo grin31 " }
                        "equihash_96/5" { $AddArgs = "--algo 96_5 --pers auto " }
                        "equihash_192/7" { $AddArgs = "--algo 192_7 --pers auto " }
                        "equihash_144/5" { $AddArgs = "--algo 144_5 --pers auto " }
                        "equihash_210/9" { $AddArgs = "--algo 210_9 --pers auto " }
                        "equihash_200/9" { $AddArgs = "--algo 200_9 --pers auto " }            
                    }
                    if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }
                    [PSCustomObject]@{
                        MName      = $Name
                        Coin       = $Global:Coins
                        Delay      = $MinerConfig.$ConfigType.delay
                        Fees       = $MinerConfig.$ConfigType.fee.$($_.Algorithm)
                        Symbol     = "$($_.Symbol)"
                        MinerName  = $MinerName
                        Prestart   = $PreStart
                        Type       = $ConfigType
                        Path       = $Path
                        ArgDevices = $ArgDevices
                        Devices    = $Devices
                        Stratum    = "$($_.Protocol)://$($_.Host):$($_.Port)" 
                        Version    = "$($Global:nvidia.gminer.version)"
                        DeviceCall = "gminer"
                        Arguments  = "--api $Port --server $($_.Host) --port $($_.Port) $AddArgs--user $($_.$User) --logfile `'$Log`' --pass $($_.$Pass)$Diff $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                        HashRates  = $Stat.Hour
                        Quote      = if ($Stat.Hour) { $Stat.Hour * ($_.Price) }else { 0 }
                        Power      = if ($(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($(vars).Watts.default."$($ConfigType)_Watts") { $(vars).Watts.default."$($ConfigType)_Watts" }else { 0 } 
                        MinerPool  = "$($_.Name)"
                        API        = "gminer"
                        Port       = $Port
                        Worker     = $Rig
                        Wallet     = "$($_.$User)"
                        URI        = $Uri
                        Server     = "localhost"
                        Algo       = "$($_.Algorithm)"
                        Log        = "miner_generated"                                     
                    }
                }
            }
        }
    }
}