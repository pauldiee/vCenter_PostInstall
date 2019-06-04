@{
    vcenter = "192.168.204.128" #vCenterName
    vcenteripadress = "192.168.204.128" #vCenter IP Address
    vcenteruser = "administrator@vsphere.local"
    vcenterpass = "VMware1!" #administrator@vsphere.local password
    ntpserver = "192.168.204.1" #NTP Server Ip Adress
    dasisolation1 = "" #DAS Isolation IP 1
    dasisolation2 = "" #DAS Isolation IP 2
    datacenter = "Test" #Datacenter Object Name
    cluster = "Test" #CLuster Object Name
    dvs = "Test" #Distributed Virtual Switch Name
    rscmgmtvlan = "" #VLAN Resource Management ID
    vmotionvlan = "" #VLAN vMotion ID
    provisioningvlan = "" #VLAN Provisioning ID
    vsanvlan = "" #VLAN vSAN ID
    vsanportgroup = "vsan" #Portgroup Name vSAN
    vmotionportgroup = "vmotion" #Portgroup Name vMotion
    provisioningportgroup = "provisioning" #Portgroup Name Provisioning
    resourcemgmtportgroup = "resource-mgmt" #Portgroup Name Resource Management
    subnetmask = "255.255.255.0" #SubnetMask for all subnets
    vsangateway ="" #Gateway address vSAN
    esxiuser = "root" #ESXi Host root username
    esxipass = "VMware1!" #Lokale root ESXi password
    adminadgroup = "INFRA\DoC_INF-VCAR-0-01-Admins" #Admin group for Full Access to vCenter
}