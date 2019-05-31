$WorkingDir = Split-Path -Parent $PSCommandPath
Set-Location -Path $WorkingDir
$p = Import-PowerShellDataFile -Path ".\parameters.psd1"

Connect-VIServer $p.vcenter -User $p.vcenteruser -Password $p.vcenterpass -Force | Out-Null

$vmdrsgroups = Get-DrsClusterGroup -Cluster $p.cluster | Where-Object {$_.Name -like "*Run MER*"}
if (($vmdrsgroups | Where-Object {$_.Name -eq "Should Run MER-A"})){
    Write-Host VM Group Should Run MER-A already exists -ForegroundColor Cyan
} else{
    if ((Get-VM | Where-Object {$_.Name -eq "MERA-1"})){
        Write-Host VM MERA-1 already exists -ForegroundColor Cyan
    } else{
        $cluster = Get-Cluster $p.cluster
        New-VM -Name MERA-1 -ResourcePool $cluster -Portgroup $p.resourcemgmtportgroup | Out-Null
        Write-Host VM MERA-1 created -ForegroundColor Green
    }
    $cluster = Get-Cluster $p.cluster
    New-DrsClusterGroup -Name "Should Run MER-A" -VM MERA-1 -Cluster $cluster | Out-Null
    Write-Host VM Group Should Run MER-A created -ForegroundColor Green
}
if (($vmdrsgroups | Where-Object {$_.Name -eq "Should Run MER-B"})){
    Write-Host VM Group Should Run MER-B already exists -ForegroundColor Cyan
} else{
    if ((Get-VM | Where-Object {$_.Name -eq "MERB-1"})){
        Write-Host VM MERB-1 already exists -ForegroundColor Cyan
    } else{
        $cluster = Get-Cluster $p.cluster
        New-VM -Name MERB-1 -ResourcePool $cluster -Portgroup $p.resourcemgmtportgroup | Out-Null
        Write-Host VM MERB-1 created -ForegroundColor Green
    }
    $cluster = Get-Cluster $p.cluster
    New-DrsClusterGroup -Name "Should Run MER-B" -VM MERB-1 -Cluster $cluster | Out-Null
    Write-Host VM Group Should Run MER-B created -ForegroundColor Green
}
Disconnect-VIServer -Force -Confirm:$false