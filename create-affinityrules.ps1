$WorkingDir = split-path -parent $PSCommandPath
Set-Location -Path $WorkingDir
$p = Import-PowerShellDataFile -Path ".\parameters.psd1"

#Connect to vCenter
Connect-VIServer $p.vcenter -User $p.vcenteruser -Password $p.vcenterpass -Force | Out-Null

$checkruleexists = (Get-DrsVMHostRule -Cluster $p.cluster).Name.Contains("Should run in MER-A")
while ($checkruleexists -eq $false){
    #Create Affinity Rules for MER-A
    if ((Get-DrsClusterGroup -Cluster $p.cluster).Name.Contains("Should Run MER-A")){    
        if ((Get-DrsClusterGroup -Cluster $p.cluster).Name.Contains("MER-A")){        
            if ((Get-DrsVMHostRule -Cluster $p.cluster | Where-Object {$_.Name -eq "Should run in MER-A"})){
                Write-Host DRS Affinity Rule for MER A already exists -ForegroundColor Cyan
            } else{
                New-DrsVMHostRule -Cluster $p.cluster -Name "Should run in MER-A" -VMGroup "Should Run MER-A" -VMHostGroup "MER-A" -Type ShouldRunOn -Enabled $true | Out-Null
                $checkruleexists = (Get-DrsVMHostRule -Cluster $p.cluster).Name.Contains("Should run in MER-A")
                Write-Host Created DRS Affinity Rule for MER A -ForegroundColor Green
            }
        } else{
            $MERAHosts = (Get-Cluster $p.cluster) | Get-VMHost -Name dc1*
            New-DrsClusterGroup -Name "MER-A" -Cluster $p.cluster -VMHost $MERAHosts | Out-Null
            Write-Host DRS Host Group MER-A created -ForegroundColor Green        
        }
    } else{    
        if ((Get-VM | Where-Object {$_.Name -eq "MERA-1"})){
            Write-Host VM MERA-1 already exists -ForegroundColor Cyan
        } else{
            $cluster = Get-Cluster $p.cluster
            New-VM -Name MERA-1 -ResourcePool $cluster -Portgroup $p.resourcemgmtportgroup | Out-Null
            Write-Host VM MERA-1 created -ForegroundColor Green
        }
        New-DrsClusterGroup -Name "Should Run MER-A" -VM MERA-1 -Cluster $p.cluster | Out-Null
        Write-Host VM Group Should Run MER-A created -ForegroundColor Green
        if ((Get-VM | Where-Object {$_.Name -eq "MERA-1"})){
            get-vm MERA-1 | Remove-VM -DeletePermanently -Confirm:$false -RunAsync | Out-Null
            Write-Host VM MERA-1 Removed -ForegroundColor Green
        } else {
            Write-Host VM MERA-1 already Removed -ForegroundColor Cyan
        }
    }
}
Disconnect-VIServer -Force -Confirm:$false | Out-Null