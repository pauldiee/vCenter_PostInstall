####
#
# SCript om StorCLI te installeren op alle hosts binnen 1 cluster
# hoi
#
# Randvoorwaarden:
# HFS op Allow in windows Firewall
# VIB gepubliceerd via HFS.
# Variabelen aangepast aan omgeving
####


#Variabelen Defineren
$Cluster = "Resource-Cluster"
$vcenter = "inf-vcar-0-01.clusum.nl"

$VIBPATH = "http://10.2.1.4/vmware-storcli-007.0504.0000.0000.vib"


# Connect to vCenter
Connect-VIServer -Server $vcenter

#Installeren VIB op elke host
Get-VMhost -Location $Cluster | where { $_.PowerState -eq "PoweredOn" -and $_.ConnectionState -eq "Connected" } | foreach {

    Write-host "Preparing $($_.Name) for ESXCLI" -ForegroundColor Yellow

    $ESXCLI = Get-EsxCli -VMHost $_

    # Install VIBs
    Write-host "Installing VIB on $($_.Name)" -ForegroundColor Yellow
    $action = $ESXCLI.software.vib.install($null,$null,$null,$null,$null,$true,$null,$null,$VIBPATH)

    # Verify VIB installed successfully
    if ($action.Message -eq "Operation finished successfully."){Write-host "Action Completed successfully on $($_.Name)" -ForegroundColor Green} else {Write-host $action.Message -ForegroundColor Red}
}

#Disk
Disconnect-VIServer -Confirm:$false