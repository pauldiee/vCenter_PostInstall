<#
=============================================================================================================
Script:    		    set-ntp.ps1
Date:      		    June, 2019
Create By:          Paul van Dieën
Last Edited by:	    Paul van Dieën
Last Edited Date:   04-06-2019
Requirements:		Powershell Framework 5.1
                    PowerCLI 11.2
=============================================================================================================
.DESCRIPTION
This script will set NTP config on all Hosts in the Cluster.
#>
$WorkingDir = split-path -parent $PSCommandPath
Set-Location -Path $WorkingDir
$p = Import-PowerShellDataFile -Path ".\parameters.psd1"

$vcenter = "" #enter vcenter name
Connect-VIServer -Force

#Configure NTP server
$esxihosts = get-cluster $p.cluster |get-vmhost
foreach ($esx in $esxihosts){
    if ((Get-VMHostNtpServer -VMHost $esx | Where-Object {$_.Name -ne $p.ntpserver})){
        Write-Host NTP Server already set on $esx -ForegroundColor Cyan
    } else {
        Add-VmHostNtpServer -VMHost $esx -NtpServer $p.ntpserver | Out-Null
        #Allow NTP queries outbound through the firewall
        Get-VMHostFirewallException -VMHost $esx | Where-Object {$_.Name -eq "NTP client"} | Set-VMHostFirewallException -Enabled:$true  | Out-Null
        #Start NTP client service and set to automatic
        Get-VmHostService -VMHost $esx | Where-Object {$_.key -eq "ntpd"} | Start-VMHostService  | Out-Null
        Get-VmHostService -VMHost $esx | Where-Object {$_.key -eq "ntpd"} | Set-VMHostService -policy "automatic"  | Out-Null
        Write-Host Done setting up NTP on $esx -ForegroundColor Green
    }
}
Disconnect-VIServer -Force -Confirm:$false