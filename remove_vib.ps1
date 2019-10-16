####
#
# SCript om vib te verwijderen op alle hosts binnen 1 cluster
# hoi
#
# Randvoorwaarden:
# HFS op Allow in windows Firewall
# VIB gepubliceerd via HFS.
# Variabelen aangepast aan omgeving
####


#Variabelen Defineren
$Cluster = "Infra-Cluster"
$vcenter = "inf-vcai-0-01.infra.local"

$vibname = "vmware-storcli-007.0504.0000.0000"

# Connect to vCenter
Connect-VIServer -Server $vcenter

#De-Installeren VIB op elke host
Get-VMhost -Location $Cluster | where { $_.PowerState -eq "PoweredOn" -and $_.ConnectionState -eq "Connected" } | foreach {

    Write-host "Preparing $($_.Name) for ESXCLI" -ForegroundColor Yellow

    $ESXCLI = Get-EsxCli -VMHost $_

    # Remove VIBs
    Write-host "Removing VIB on $($_.Name)" -ForegroundColor Yellow
    $action = $ESXCLI.software.vib.remove($false, $false, $false, $true, $vibname)

    # Verify VIB removed successfully
    if ($action.Message -eq "Operation finished successfully."){Write-host "Action Completed successfully on $($_.Name)" -ForegroundColor Green} else {Write-host $action.Message -ForegroundColor Red}
}

#Disk
Disconnect-VIServer -Confirm:$false