$WorkingDir = split-path -parent $PSCommandPath
Set-Location -Path $WorkingDir
$p = Import-PowerShellDataFile -Path ".\parameters.psd1"

Connect-VIServer $p.vcenter -User $p.vcenteruser -Password $p.vcenterpass -Force | Out-Null

#Add 10 Hosts to vCenter 5 per MER (Cluster and Datacenter)
if ((Get-Cluster |Where-Object {$_.Name -eq $p.cluster})){
    1..1 | Foreach-Object {
        if (($check = Get-VMHost 192.168.204.129 -ErrorAction SilentlyContinue)){
            Write-Host Host 192.168.204.129 already exists. -ForegroundColor Cyan
        } else{
            Add-VMHost 192.168.204.129 -Location  (Get-Cluster $p.cluster) -User $p.esxiuser -Password $p.esxipass -force:$true | Out-Null
            Write-Host Host 192.168.204.129 added to $p.cluster -ForegroundColor Green
        }
    }
    #1..1 | Foreach-Object { 
        #if (($check = Get-VMHost dc2-esxi-2-0$_.infra.local -ErrorAction SilentlyContinue)){
            #Write-Host Host dc1-esxi-2-0$_.infra.local already exists. -ForegroundColor Cyan
        #} else{
            #Add-VMHost dc2-esxi-2-0$_.infra.local -Location (Get-Cluster $p.cluster) -User $p.esxiuser -Password $p.esxipass -force:$true | Out-Null
            #Write-Host Host dc2-esxi-2-0$_.infra.local added to $p.cluster -ForegroundColor Green
        #}
    #}
} else {
    Write-Host Cluster $p.cluster does not exist! -ForegroundColor Cyan
}
Disconnect-VIServer -Force -Confirm:$false