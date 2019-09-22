<#
=============================================================================================================
Script:    		    connect-dvs-config-vswitch0.ps1
Date:      		    June, 2019
Create By:          Paul van Dieën
Last Edited by:	    Paul van Dieën
Last Edited Date:   04-06-2019
Requirements:		Powershell Framework 5.1
                    PowerCLI 11.2
=============================================================================================================
.DESCRIPTION
This script will connect DVS created by create-switch-portgroups.ps1 to all hosts in the cluster. Script Assumes the use of 4 physical nics. 
The First 2 are connected to vSwitch0 and the last 2 are connected to the Distributed vSwitch.
#>
$WorkingDir = split-path -parent $PSCommandPath
Set-Location -Path $WorkingDir
$p = Import-PowerShellDataFile -Path ".\parameters.psd1"

Connect-VIServer $p.vcenter

#Create 1 diskgroup of 8 disks on each host
$cluster = "$p.cluster"
$esxihosts = get-cluster $p.cluster |get-vmhost
ForEach ($esxi in $esxihosts){
    # Get Start Time
    $startDTM = (Get-Date)
    
    #diskgroep definities voor 8 disken in 1 diskgroep
    $diskgroup1="s1,"
    $diskgroup2="s1,2,3,4,5,6,7,8"
    $diskgroup3="s1,2,3,4,5,6,7,8"
    $diskgroup4="s1,2,3,4,5,6,7,8"
    $Diskgroups =$diskgroup1

    #enable SSH
    Get-VMHost $esxi | ForEach-Object {Start-VMHostService -HostService ($_ | Get-VMHostService | Where-Object { $_.Key -eq "TSM-SSH"} )}

    #Opbouwen SSH Sessie
    New-SSHSession -ComputerName "$esxi" -Credential $esxicredential -Acceptkey

    ForEach ($i in $Diskgroups){

        #Stap1: Opvragen WWN obv SLOTID
        $getdiskgroup= $(Invoke-SSHCommand -SessionID 0 -command "/opt/lsi/storcli/storcli /c0/e15/$i show all|grep 'WWN'")

        #Loop door de output om de WWNs te strippen en vervolgens in een aray te stoppen
        $disk3 = @()
            foreach ($disk in $getdiskgroup.Output) {
                $disk2 = $disk.split("=")[-1]
                $disk3 += "naa.$($disk2.TrimStart())"
            }

        #Creeer de diskgroup met de hierboven verkegen WWNs - pas deze aan als het aantal disks anders is dan 8 per diskgroep
        New-VsanDiskGroup -VMHost $esxi -SsdCanonicalName $disk3[0] -DataDiskCanonicalName $disk3[1],$disk3[2],$disk3[3],$disk3[4],$disk3[5],$disk3[6],$disk3[7]
}
    #Maak een csv aan met de diskgroup info voor de host
    get-vsandisk -vmhost $esxi |Select-Object VsanDiskGroup, CanonicalName |Export-Csv $WorkingDir\${esxi}.diskgroups.csv
    #DisableSSH
    Get-VMHostService -VMHost $esxi | Where-Object {$_.Key -eq "TSM-SSH" } | Stop-VMHostService -Confirm:$false

    #Opruimen SSH Sessie
    remove-sshsession -SessionId 0
    
    # Get End Time
    $endDTM = (Get-Date)

    $duration=$($endDTM-$startDTM)
    # Echo Time elapsed
    Write-Host "Verstreken Tijd: $($duration.Minutes) Minuten"

}