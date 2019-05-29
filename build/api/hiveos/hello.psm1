<#
SWARM is open-source software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
SWARM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>
function Start-Hello($RigData) {

    $AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols


    $Hello = @{
        method  = "hello"
        jsonrpc = "2.0"
        id      = "0"
        params  = @{
            farm_hash        = "$($global:Config.Params.Farm_Hash)"
            server_url       = "$($global:Config.hive_params.HiveMirror)"
            uid              = $RigData.uid
            boot_time        = "$($RigData.boot_time)"
            boot_event       = "0"
            ip               = "$($RigData.ip)"
            net_interfaces   = ""
            openvpn          = "0"
            lan_config       = ""
            gpu              = $RigData.gpu
            gpu_count_amd    = "$($RigData.gpu_count_amd)"
            gpu_count_nvidia = "$($RigData.gpu_count_nvidia)"
            worker_name      = "$($global:Config.hive_params.HiveWorker)" 
            version          = ""
            kernel           = "$($RigData.kernel)"
            amd_version      = "$($RigData.amd_version)"
            nvidia_version   = "$($RigData.nvidia_version)"
            mb               = @{
                manufacturer = "$($RigData.mb.manufacturer)"
                product      = "$($RigData.mb.product)" 
            }
            cpu              = @{
                model  = "$($RigData.cpu.model)"
                cores  = "$($RigData.cpu.cores)"
                aes    = "$($RigData.cpu.aes)"
                cpu_id = "$($RigData.cpu.cpu_id)"
            }
            disk_model       = "$($RigData.disk_model)"
        }
    }
      
    Write-Log "Saying Hello To Hive"
    $GetHello = $Hello | ConvertTo-Json -Depth 3 -Compress
    $GetHello | Set-Content ".\build\txt\hello.txt"
    Write-Log "$GetHello" -ForegroundColor Green

    try {
        $response = Invoke-RestMethod "$($Global:Config.hive_params.HiveMirror)/worker/api" -TimeoutSec 15 -Method POST -Body ($Hello | ConvertTo-Json -Depth 3 -Compress) -ContentType 'application/json'
        $response | ConvertTo-Json | Out-File ".\build\txt\get-hive-hello.txt"
        $message = $response
    }
    catch { $message = "Failed To Contact HiveOS.Farm" }

    return $message
}

function Start-WebStartup($response,$Site) {
    
    switch($Site){
        "HiveOS" {$Params = "hive_params"}
        "SWARM" {$Params = "SWARM_Params"}
    }

    if ($response.result) { $RigConf = $response }
    elseif (Test-Path ".\build\txt\get-hive-hello.txt") {
        Write-Log "WARNGING: Failed To Contact HiveOS. Using Last Known Configuration"
        Start-Sleep -S 2
        $RigConf = Get-Content ".\build\txt\get-hive-hello.txt" | ConvertFrom-Json
    }
    if ($RigConf) {
        $RigConf.result | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
            $Action = $_
            Switch ($Action) {
                "config" {
                    $Rig = [string]$RigConf.result.config | ConvertFrom-StringData                
                    $global:Config.$Params.HiveWorker = $Rig.WORKER_NAME -replace "`"", ""
                    $global:Config.$Params.HivePassword = $Rig.RIG_PASSWD -replace "`"", ""
                    $global:Config.$Params.HiveMirror = $Rig.HIVE_HOST_URL -replace "`"", ""
                    $global:Config.$Params.FarmID = $Rig.FARM_ID -replace "`"", ""
                    $global:Config.$Params.HiveID = $Rig.RIG_ID -replace "`"", ""
                    $global:Config.$Params.Wd_enabled = $Rig.WD_ENABLED -replace "`"", ""
                    $global:Config.$Params.Wd_Miner = $Rig.WD_MINER -replace "`"", ""
                    $global:Config.$Params.Wd_reboot = $Rig.WD_REBOOT -replace "`"", ""
                    $global:Config.$Params.Wd_minhashes = $Rig.WD_MINHASHES -replace "`"", ""
                    $global:Config.$Params.Miner = $Rig.MINER -replace "`"", ""
                    $global:Config.$Params.Miner2 = $Rig.MINER2 -replace "`"", ""
                    $global:Config.$Params.Timezone = $Rig.TIMEZONE -replace "`"", ""

                    if (Test-Path ".\build\txt\hivekeys.txt") { $OldHiveKeys = Get-Content ".\build\txt\hivekeys.txt" | ConvertFrom-Json }

                    ## If password was changed- Let Hive know message was recieved

                    if ($OldHiveKeys) {
                        if ("$($global:Config.$Params.HivePassword)" -ne "$($OldHiveKeys.HivePassword)") {
                            $method = "message"
                            $messagetype = "warning"
                            $data = "Password change received, wait for next message..."
                            $DoResponse = Set-Response -Method $method -MessageType $messagetype -Data $data -CommandID $command.result.id -Site $Site
                            $sendResponse = $DoResponse | Invoke-WebCommand -Site $Site -Action "Message"
                            $SendResponse
                            $DoResponse = @{method = "password_change_received"; params = @{rig_id = $global:Config.$Params.HiveID; passwd = $global:Config.$Params.HivePassword }; jsonrpc = "2.0"; id = "0" }
                            $send2Response = $DoResponse | Invoke-WebCommand -Site $Site -Action "Message"
                        }
                    }

                    ## Set Arguments/New Parameters
                    $global:Config.$Params | ConvertTo-Json | Set-Content ".\build\txt\$($Params)_keys.txt"
                }

                ##If Hive Sent OC Start SWARM OC
                "nvidia_oc" {
                    Start-NVIDIAOC $RigConf.result.nvidia_oc 
                }
                "amd_oc" {
                    Start-AMDOC $RigConf.result.amd_oc
                }
            }
        }
        ## Print Data to output, so it can be recorded in transcript
        $RigConf.result.config
    }
    else {
        write-Log "No HiveOS Rig.conf- Do you have an account? Did you use your farm hash?"
        write-Log "Try running Hive_Windows_Reset.bat then try again."
        Start-Sleep -S 2
    }
}