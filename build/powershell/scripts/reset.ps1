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
Set-Location (Split-Path (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path))))
$dir = (Split-Path (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path))))
Write-Host "Clearing All Previous Stored HiveOS Data"
if(test-path ".\build\txt"){Remove-Item ".\build\txt\*" -Force}
if(test-path ".\config\parameters\newarguments.json"){Remove-Item ".\config\parameters\newarguments.json" -Force}
if(test-Path ".\config\parameters\arguments.json"){Remove-Item ".\config\parameters\arguments.json" -Force}
Write-Host "All Data Is Removed!"