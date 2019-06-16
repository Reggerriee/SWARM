## Confirm Answer Is Correct
$Global:config = @{ }
$Global:Config.Add("vars", @{ })
$Global:Config.vars.Add( "dir", (Split-Path $script:MyInvocation.MyCommand.Path) )
$Global:Config.vars.dir = $Global:Config.vars.dir -replace "/var/tmp", "/root"
Set-Location $Global:Config.vars.dir
. .\build\powershell\global\modules.ps1

$(vars).Add("config", [ordered]@{ })
$(vars).config = @{ }

function Global:Confirm-Answer($Answer, $Possibilities) {
    if ($Answer -notin $Possibilities) {
        if ($Possibilities.count -gt 10) {
            Write-Host "Invalid Selection" -ForegroundColor Red
        }
        else {
            Write-Host "Please Select The Following: $Possibilities" -ForegroundColor Red
        }
        Start-Sleep 3
        return 1
    }
    else { return 2 }
}

##CPU Question- Asked in multiple locations
function Start-CPU_Question {
    do {
        Clear-Host
        $ans3 = Read-Host -Prompt "Would you like to CPU mine with this machine as well?
  
 1 Yes
 2 No
       
 Answer"
        $Check = Global:Confirm-Answer $ans3 @("1", "2")
    }while ($Check -eq 1)
  
    if ($ans3 -eq "1") {
        do {
            Clear-Host
            $ans4 = Read-Host -Prompt "How many cpu threads would you like to use?
  
  Enter number of threads"
  
            do {
                clear-host
                $ans5 = Read-Host -Prompt "You have entered $ans4 threads. Is this correct?
  
  1 Yes
  2 No
  
  Answer"
                $Check = Global:Confirm-Answer $ans5 @("1", "2")
            }while ($Check -eq 1)
        }while ($ans5 -ne "1")
    }
    if ($ans3 -eq 1) {
        $(vars).config.Type += "CPU"
        $(vars).config.Add("CPUThreads", [int]$ans4)
    }
}

function Global:Get-Advanced_Settings {
    do {
        $ans = Read-Host -Prompt "These are advanced configs. More information regarding advanced parameters can be found here:
    
https://github.com/MaynardMiner/SWARM/blob/master/help/SWARM_help.txt

Please choose an advanced setting you wish to modify:

[Strategy]
1 My -Wallet address was not a BTC address. I want to specify its symbol (-PasswordCurrency)
2 I want to add altcoin wallets to use if available on pool (-AltWallet & -AltPassword)
3 I wish to modify the time SWARM takes to benchmark an algorithm (-Benchmark)
4 I wish SWARM to not mine when Profit/Day is negatve (-Conserve)
5 I don't want SWARM to mine all available algorithms. I want to mine a specific amount (-Algorithm)
6 I want to mine a particular coin (-Coin)

[Switching]
7 I want SWARM to switch by specific coins, not algorithms if possible. (-Auto_Coin)
8 I want to turn off/on Auto_Algo switching (-Auto_Algo)
9 I wish to change the interval period in which SWARM queries pools for stats (-Interval)
10 I wish to activate SWARM_MODE, so that all my rigs switch at the same time (-SWARM_MODE)
11 I want to set a minimum runtime before SWARM records hashrates. (-StatsInterval)
12 I wish to increase the minimum threshold before SWARM decides to switch (-Switch_Threshold)

[Statistics]
13 I wish to change the time frame algorithm estimates are based on (-Stat_Algo)
14 I wish to change the time frame coin estimates are based on (-Stat_Coin)
15 I want SWARM to favor pool with the most hashrate. (-Volume)
16 I wish to turn off/on WattOMeter for power/day calculations. (-WattOMeter)
17 I wish to specify my kilowatt/hour cost of electricity. (-KWH)
18 I wish to change the maximum periods of estimates SWARM will save (-Max_Periods)
19 I wish to stat all coins all the time, not just when it is most profitable (-Stat_All)
20 I wish to define a custom period rather than time frame from statistics (-Custom_Periods)

[Admin]
21 There is an algorithm/miner/pool giving me problems. I wish to disable it (-Bans)
22 I wish to ban GlobalToken coins (-Ban_GLT)
23 I wish to increase the maximum number of issues before SWARM bans a selected pool (-PoolBanCount)
24 I wish to increase the maximum number of issues before SWARM bans a algorithm (-AlgoBanCount)
25 I wish to ammend the threshold in which SWARM considers the profit/day to be too high to be accurate (-ThreshHold)
26 I wish to increase the rejection % before SWARM considers a ban (-Rejections)
27 I want to add an optional/old miner. (-Optional)
28 I want to specify extranonce.subscribe (-XNsub)

[Interface]
29 I want to add/remove pool share tracking (-Track_Shares)
30 I wish the stats screen to show an additional altcoin/day value (-CoinExchange)
31 I wish to change the default fiat currency from USD (-Currency)
32 I wish to turn off/on HiveOS website stats (-HiveOS)
33 I wish to turn on CPUOnly for HiveOS (-CPUOnly)

[API]
34 I wish to turn on html API (-API)
35 I wish to make html work remotely (-Remote)
36 I wish to set an API password (-APIPassword)
37 I wish to turn on TCP API (-TCP)
38 I wish to set TCP Port (-TCP_Port)

[Maintence/Troubleshooting]
39 I want to force SWARM to use a specific platform (windows,linux) (-Platform)
40 I do not wish SWARM to run at Windows startup (-Startup)
41 SWARM is not detecting the correct OpenCL platform for AMD (-CLPlatform)
42 I wish to turn on updates (-Update)

Answer"
        $A = 42
        $Num = 0
        $CheckArray = @()
        for ($i = 0; $i -lt $A; $i++) { $CheckArray += ($Num + 1); $Num++ }
        $Check = Global:Confirm-Answer $ans $CheckArray
    }While ($Check -eq 1)
    $ans
}

##Ans 3 = CPU
##And 4 = CPUTHreads

Clear-Host

Write-Host "Hello! Welcome to SWARM's guided setup!" -ForegroundColor Green
Start-Sleep -S 3
Write-Host "

We are very glad you are ready to get that lambo." -ForegroundColor Yellow
Start-Sleep -S 1
Write-Host "


                              _.-=`"_-         _
                         _.-=`"   _-          | ||`"`"`"`"`"`"---._______     __..
             ___.===`"`"`"`"-.______-,,,,,,,,,,,,`-''----`" `"`"`"`"`"       `"`"`"`"`"  __'
      __.--`"`"     __        ,'                   o \           __        [__|
 __-`"`"=======.--`"`"  `"`"--.=================================.--`"`"  `"`"--.=======:
]       [w] : /        \ : |========================|    : /        \ :  [w] :
V___________:|          |: |========================|    :|          |:   _-`"
 V__________: \        / :_|=======================/_____: \        / :__-`"
  -----------' `"-____-`"   `-------------------------------'  `"-____-`"
" -foregroundcolor "red"
Start-Sleep -S 2
Write-Host "


You deserve it." -ForegroundColor Green
Start-Sleep -S 3

Clear-Host
$DoBasic = $true

if (Test-Path ".\config\parameters\newarguments.json") {
    do {
        Clear-Host
        $ans = Read-Host -Prompt "It seems you have previous configs saved.
Would you like to load them, and skip basic configuration?

1 Yes - Do I look like a newb?
2 No - I want a do-over.

Answer"
        $Check = Global:Confirm-Answer $ans @("1", "2")
    }While ($Check -eq 1)
    if ($ans -eq 1) {
        $DoBasic = $false
        $(vars).config = @{ }
        $Defaults = Get-Content ".\config\parameters\newarguments.json" | ConvertFrom-Json
        $Defaults.PSObject.Properties.Name | % { if ($_ -notin $(vars).config.keys) { $(vars).config.Add("$($_)", $Defaults.$_) } }
    }
}

if ($DoBasic -ne $false) {
    do {
        clear-host
        $tutorial = Read-Host -Prompt "First We Need To Determine What You Are Mining With.

Are you GPU mining or mining with an ASIC?

1. GPU mining.
2. ASIC mining.
3. Both.

Answer"
        $Check = Global:Confirm-Answer $tutorial @("1", "2", "3")
        if ($Check -eq 1) { continue }
    }while ($Check -eq 1)

    if ($tutorial -eq "1" -or $tutorial -eq "3") {
        do {
            Clear-Host
            do {
                clear-host
                $ans = Read-Host -Prompt "Okay, Now we need to know what kind of GPUs
     
1. I have NVIDIA GPUs
2. I have AMD GPUs
3. I have both AMD and NVIDIA GPUs
     
Answer"
                $Check = Global:Confirm-Answer $ans @("1", "2", "3")
            }while ($Check -eq 1)

            switch ($ans) {
                "1" {
                    do {
                        Clear-Host
                        $ans2 = Read-Host -Prompt "NVIDIA GPUs can be divided, and separated into different device groups. 
                
How many groups would you like to have?
     
1. NVIDIA1 (1 group)
2. NVIDIA1,NVIDIA2 (2 groups)
3. NVIDIA1,NVIDIA2,NVIDIA3 (3 groups)
             
Answer"
                        $Check = Global:Confirm-Answer $ans2 @("1", "2", "3")
                    }while ($Check -eq 1)

                    switch ($ans2) {
                        "1" { $(vars).config.Add("Type", @("NVIDIA1")) }
                        "2" { $(vars).config.Add("Type", @("NVIDIA1", "NVIDIA2")) }
                        "3" { $(vars).config.Add("Type", @("NVIDIA1", "NVIDIA2", "NVIDIA3")) }
                    }

                    if ($(vars).config.Type.Count -gt 1) {
                        Clear-Host
                        Write-Host "You have chosed to divide rig. You must specify GPUs for each group"

                        $(vars).config.Type | Foreach {
                            $Group = $_ -replace "NVIDIA", ""
                            $ans2 = Read-Host -Prompt "
3Please specify devices used for Group $Group

Example: To use first, second, and third GPUs:

0,1,2

Answer"
                            $(vars).config.Add("GPUDevices$Group", @($ans2 -split "," | % { [int]$_ }))
                        }
                    }
                    Start-CPU_Question
                }
                "2" { $(vars).config.Add("Type", @("AMD1")); Start-CPU_Question }
                "3" { $(vars).config.Add("Type", @("AMD1", "NVIDIA2")); Start-CPU_Question }
            }
    
            clear-host

            do {
                clear-host
                $(vars).config
                $Confirm = Read-Host "

Does this look correct?

1 Yes
2 No

Answer"
                $Check = Global:Confirm-Answer $Confirm @("1", "2")
            }while ($Check -eq 1)

            if ($Confirm -ne 1) {
                Write-Host "

Okay, let's try again."
                $(vars).config.Remove("Type")
                if ($(vars).config.GPUDevices1) { $(vars).config.Remove("GPUDevices1") }
                if ($(vars).config.GPUDevices2) { $(vars).config.Remove("GPUDevices2") }
                if ($(vars).config.GPUDevices3) { $(vars).config.Remove("GPUDevices3") }
                Start-Sleep -S 3
            }
        }while ($Confirm -ne 1)

        clear-host

    }
    ## DO ASIC
    if ($tutorial -eq "2" -or $tutorial -eq "3") {

        if (-not $(vars).config.Type) {
            $(vars).config.Add("Type", @())
        }
        else { $(vars).config.Type += "ASIC" }
        
        do {
            do {
                Clear-Host
                $ans = Read-Host -Prompt "Okay, Now we need gather informationa about ASICS.

Before we continue- It should be noted that SWARM does not work with all ASICS. If it
does not work for you, please contact developer, and he will attempt to rectify.

Note: SWARM cannot open ports/networking for ASIC. If not being used locally: You
must ensure ports are forwards, and firewalls are disabled.

SWARM attempt to communicate through ASICS Through Port 4028. ASICs must have
their API enabled and listening.

How many ASICS do you wish SWARM to monitor?

Answer"

                try { [int]$ans }catch { Write-Host "Answer must be a number"; Start-Sleep -S 3; continue }

                do {
                    Clear-Host
                    $Confirm = Read-Host -Prompt "You have specified $ans ASICS. Is this correct?
            
1 Yes
2 No

Answer"
                    $Check = Global:Confirm-Answer $Confirm @("1", "2")
                }while ($Check -eq 1)
        
                if ($Confirm -eq "2") {
                    Write-Host "Okay, let's try again."
                    Start-Sleep -S 3
                    continue
                }
            }while ($Confirm -ne "1")

            $(vars).config.Add("ASIC_IP", @())

            for ($i = 0; $i -lt [int]$ans; $i++) {
                do {
                    clear-host
                    Write-Host "Lets Do ASIC `#$($i+1)
"
                    $ans1 = Read-Host -Prompt "What is IP of ASIC `#$($i+1)?

Answer"
                    clear-host
                    $ans2 = Read-Host -Prompt "What is Nickname of ASIC `#$($i+1)

Answer"
                    clear-host
                    $ans3 = Read-Host -Prompt "You have specified:
ASIC `#$($i+1) IP: $ans1
ASIC `#$($i+1) Nickname: $ans2

Is This Correct?

1 Yes
2 No

Answer"
                    $Check = Global:Confirm-Answer $ans3 @("1", "2")
                    if ($ans3 -eq "2") {
                        Write-Host "Okay, lets try again."
                        Start-Sleep -S 3
                        continue
                    }
                }while ($ans3 -eq "2")
            
                $(vars).config.ASIC_IP += "$ans1`:$ans2"
            }

            do {
                Clear-Host
                $(vars).config.ASIC_IP

                $Confirm = Read-Host -Prompt "
This is the current list of Array ASIC_IP

Is this correct?

1 Yes
2 No

Answer"
                $Check = Global:Confirm-Answer $Confirm @("1", "2")
            }while ($Check -eq 1)

            if ($Confirm -eq "2") {
                Write-Host "Okay, lets try again"
                $(vars).config.Remove("ASIC_IP")
                Start-Sleep -S 3
                continue
            }
        }while ($Confirm -eq "2")

        do {
            Clear-Host
            $ans = Read-Host -Prompt "Now we must determine ASIC mining algorithms.

Please specify algorithms you wish to use. These name should match the pools
you wish to mine on. If pools use different names for the same algorithm-
You must add both names. These names should be comma seperated

Example:

x11,scrypt,sha256

Answer"
    
            $ans1 = Read-Host -Prompt "You have chosen the following algorithms
     
$ans

Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $ans1 @("1", "2")
        }while ($Check -eq 1)

        $List = $ans1 -split ","
        $(vars).config.Add("ASIC_ALGO", $List)
    }

    ## Location Question
    do {
        Clear-Host
        do {
            Clear-Host
            $ans = Read-Host -Prompt "Next where are you located?

1 EUROPE
2 US
3 ASIA

Answer"
            $Check = Global:Confirm-Answer $ans @("1", "2", "3")
        }while ($Check -eq 1)

        Switch ($ans) {
            "1" { $choice = "EUROPE" }
            "2" { $choice = "US" }
            "3" { $choice = "ASIA" }
        }
        Clear-Host
        do {
            Clear-Host
            $ans2 = Read-Host -Prompt "Your Location is $choice. Is this correct?
  
1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $ans2 @("1", "2")
        }while ($Check -eq 1)

    }while ($ans2 -ne "1")

    $(vars).config.Add("Location", $choice)

    ## BTC Wallet Addresses
    do {
        Clear-Host
        $Max_Wallets = ($(vars).config.Type | Where { $_ -like "*NVIDIA*" }).Count
        if ( $Max_Wallets -gt 1 ) {
            for ($i = 0; $i -lt $Max_Wallets; $i++ ) {
                Clear-Host
                $ans = Read-Host -Prompt "Please Enter BTC Wallet For Device Group $($i+1)"
                $(vars).config.Add("Wallet$($i+1)", $ans)
            }
        }
        else {
            $ans = Read-Host -Prompt "Please Enter BTC Wallet"
            $(vars).config.Add("Wallet1", $ans)
        }
        do {
            Clear-Host
            $(vars).config
            $Confirm = Read-Host -Prompt "

Does everything look correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1", "2")
        }While ($Check -eq 1)
        if ($Confirm -ne 1) {
            Write-Host "Okay, Let's Try again!"
            if ($(vars).config.Wallet1) { $(vars).config.Remove("Wallet1") }
            if ($(vars).config.Wallet2) { $(vars).config.Remove("Wallet2") }
            if ($(vars).config.Wallet3) { $(vars).config.Remove("Wallet3") }
            Start-Sleep -S 3
        }
    }while ($Confirm -ne 1)

    ## Pools

    do {
        clear-host
        $PoolList = [ordered]@{ }
        $Num = 0
        Get-ChildItem ".\algopools" | ForEach-Object { $PoolList.Add("$($_.BaseName)", $Num); $Num++ }
        Get-ChildItem ".\custompools" | ForEach-Object { $PoolList.Add("$($_.BaseName)", $Num); $Num++ }
        $Message = @()
        $PoolList.keys | % { $Message += "$($PoolList.$_) $($_)" }
        $ans = Read-Host -Prompt "Now We Must Decide Pools. 
This is a list of Pools SWARM can use. 
Please choose which ones you would like to use
Comma separating each selection (i.e. 1,3,5)

$($Message -join "`n")

Answer"

        $Pools = @()

        try {
            $list = $ans -split ","
            $list | % { 
                $Sel = [int]$_
                $Pools += $PoolList.Keys | % { if ( $PoolList.$_ -eq $Sel ) { $_ } }
            }
        }
        catch { Write-Host "Failed To Parse Selection, Try Again" -Foreground Red; Start-Sleep -S 3; continue }

        do {
            Clear-Host
            $Confirm = Read-Host -Prompt "The pools you have chosen are:
 
$($Pools -join "`n")
 
Is this Correct?

1 Yes
2 No
 
Answer"
            $Check = Global:Confirm-Answer $Confirm @("1", "2")
        }While ($Check -eq 1)

        if ($Confirm -ne "1") {
            Write-Host "Okay, let's try again"
            Start-Sleep -S 3
        }
    }While ($Confirm -ne "1")

    $(vars).config.Add("PoolName", $Pools)

    if ("whalesburg" -in $Pools) {
        do {
            clear-host
            Write-Host "You have specified the custom pool whalesburg.
In order to mine there- Two things are neccessary:

-You have an ETH address to mine to.

-You have an account, which can be done here:

https://whalesburg.com/sign_up

Please do these first before continuing."

            $ans1 = Read-Host -Prompt "
please enter your whalesburg worker name"
            $ans2 = Read-Host -Prompt "
please enter your ETH address"

            do {
                clear-host
                $Confirm = Read-Host -Prompt "
Whalesburg Worker = $ans1
ETH Address = $ans2
 
Is this Correct?

1 Yes
2 No

Answer"
                $Check = Global:Confirm-Answer $Confirm @("1", "2")
            }while ($Check -eq 1)
            if ($Confirm -ne "1") {
                Write-Host "Okay, let's try again."
                Start-Sleep -S 3
                continue
            }
        }While ($Confirm -ne "1")

        $(vars).config.Add("Worker", $ans1)
        $(vars).config.Add("ETH", $ans2)
    }

    if ("nicehash" -in $Pools) {
        do {
            clear-Host

            do {
                clear-host
                $ans = Read-Host -Prompt "You have specified Nicehash as a pool.
Would you like to add your nicehash wallet?

1 Yes
2 No

Answer"
                $Check = Global:Confirm-Answer $ans @("1", "2")
            }while ($Check -eq 1)

            if ($ans -eq "1") {
                do {
                    clear-Host
                    $nice = Read-Host -Prompt "Please Enter Your Nicehash Address"
                    do {
                        clear-host
                        $Confirm = Read-Host -Prompt "You enetered $nice
Is This Correct?

1 Yes
2 No

Answer"
                        $Check = Global:Confirm-Answer $Confirm @("1", "2")
                    }While ($Check -eq 1)
                    if ($Confirm -ne "1") {
                        Write-Host "Okay, lets try again"
                    }
                }While ($Confirm -ne "1")
            }
            else { $confirm = "1" }
        }While ($Confirm -ne "1")
    }

    if ($nice) {
        $(vars).config.Type | % {
            switch ($_) {
                "AMD1" { if (-not $(vars).config.Nicehash_Wallet1) { $(vars).config.Add("Nicehash_Wallet1", $nice) } }
                "NVIDIA1" { if (-not $(vars).config.Nicehash_Wallet1) { $(vars).config.Add("Nicehash_Wallet1", $nice) } }
                "CPU" { if (-not $(vars).config.Nicehash_Wallet1) { $(vars).config.Add("Nicehash_Wallet1", $nice) } }
                "ASIC" { if (-not $(vars).config.Nicehash_Wallet1) { $(vars).config.Add("Nicehash_Wallet1", $nice) } }
                "NVIDIA2" { if (-not $(vars).config.Nicehash_Wallet2) { $(vars).config.Add("Nicehash_Wallet2", $nice) } }
                "NVIDIA3" { if (-not $(vars).config.Nicehash_Wallet3) { $(vars).config.Add("Nicehash_Wallet3", $nice) } }
            }
        }
    }
}

Write-Host "Well, the basic settings are done. This is what we have so far:
"

$(vars).config

Start-Sleep -S 1

Write-Host "
These settings along with default advanced settings will be saved to `".\config\parameter\newarguments.json`""
Write-Host "If you run -help again in future, it will prompt if you wish to load your basic configs."
Write-Host "
            
If using HiveOS- You can copy and paste this into your flight sheet:

"
$Arg = $null

$(vars).config.keys | % {
    if ($(vars).config.$_ -and $(vars).config.$_ -ne "") {
        if ( $(vars).config.$_ -is [Array]) { $Sec = "$($(vars).config.$_)" -replace " ", "," }
        else { $Sec = $(vars).Config.$_ }
        $Arg += "-$($_) $Sec "
    }
}
$Arg.Substring(0, $Arg.Length - 1)      

do {
    $Confirm = Read-Host -Prompt "
            
You can now start SWARM. Would you like to save these settings, and start SWARM?

or

Would you like to start advanced configs?

1 MY BODY IS READY! LETS START SWARM!
2 No. I have plenty of time. I would like to go through all settings, knowing that it will take awhile.

Answer"
    $Check = Global:Confirm-Answer $Confirm @("1", "2")
}While ($Check -eq 1)

Clear-Host

if ($Confirm -eq "1") {
    Write-Host "Saving Settings"
    $Defaults = Get-Content ".\config\parameters\default.json" | ConvertFrom-Json
    $Defaults.PSObject.Properties.Name | % { if ($_ -notin $(vars).config.keys) { $(vars).config.Add("$($_)", $Defaults.$_) } }
    $(vars).config | ConvertTo-Json | Set-Content ".\config\parameters\newarguments.json"
    Start-Sleep -S 2
    Write-Host "Settings Saved! Run SWARM.bat to start SWARM!"
}
if ($Confirm -eq "2") {
    $(vars).add("continue", $True)
    $hd = "$($(vars).dir)\build\powershell\help"
    $(vars).Add("input", $null)
    $p = [Environment]::GetEnvironmentVariable("PSModulePath")
    if ($P -notlike "$($(vars).dir)\build\powershell\help*") {
        $P += ";$($(vars).dir)\build\powershell\help)";
        [Environment]::SetEnvironmentVariable("PSModulePath", $p)
    }            
    do {
        Clear-Host
        Write-Host "These are your current settings:
                "
        Start-Sleep -S 2
        $(vars).config
                
        Write-Host "

This is your settings in a copy/paste form for flight sheet/config:
                "
        Start-Sleep -S 2
        $Arg = $null
        $(vars).config.keys | % {
            if ($(vars).config.$_ -and $(vars).config.$_ -ne "") {
                if ( $(vars).config.$_ -is [Array]) { $Sec = "$($(vars).config.$_)" -replace " ", "," }
                else { $Sec = $(vars).Config.$_ }
                $Arg += "-$($_) $Sec "
            }
        }
        $Arg.Substring(0, $Arg.Length - 1)      
        Start-Sleep -S 2
        Write-Host ""
        Write-Host ""                
        $(vars).input = Global:Get-Advanced_Settings
        if ($(vars).input -in 1 .. 6) {
            Add-Module "$hd\strategy.psm1"
            Global:Get-Strategy
            Global:Remove-Modules
        }
        elseif ($(vars).input -in 7 .. 12) {
            Add-Module "$hd\switching.psm1"
            Global:Get-Switching
            Global:Remove-Modules
        }
        elseif ($(vars).input -in 13 .. 20) {
            Add-Module "$hd\statistics.psm1"
            Global:Get-Statistics
            Global:Remove-Modules
        }
        elseif ($(vars).input -in 21 .. 28) {
            Add-Module "$hd\admin.psm1"
            Global:Get-Admin
            Global:Remove-Modules
        }
    }While ($(vars).continue = $true)
}