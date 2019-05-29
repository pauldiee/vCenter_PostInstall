$WorkingDir = split-path -parent $PSCommandPath
Set-Location -Path $WorkingDir
$p = Import-PowerShellDataFile -Path ".\parameters.psd1"

Connect-VIServer $p.vcenter -User $p.vcenteruser -Password $p.vcenterpass -Force | Out-Null

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