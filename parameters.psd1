@{
    vcenter = "192.168.204.128" #Naam van de vCenter
    vcenteripadress = "192.168.204.128" #Ip Adress van de vCenter
    vcenteruser = "administrator@vsphere.local"
    vcenterpass = "VMware1!" #Password voor administrator@vsphere.local
    ntpserver = "192.168.204.1" #Ip Adress van de NTP Server
    dasisolation1 = "" #DAS Isolation IP 1
    dasisolation2 = "" #DAS Isolation IP 2
    datacenter = "Test" #Naam van het Datacenter Object
    cluster = "Test" #Naam van het CLuster Object
    dvs = "Test" #Naam van de Distributed Virtual Switch
    rscmgmtvlan = "" #VLAN Resource Management
    vmotionvlan = "" #VLAN vMotion
    provisioningvlan = "" #VLAN Provisioning
    vsanvlan = "" #VLAN vSAN
    vsanportgroup = "vsan" #Portgroup naam voor vSAN
    vmotionportgroup = "vmotion" #Portgroup naam voor vMotion
    provisioningportgroup = "provisioning" #Portgroup naam voor Provisioning
    resourcemgmtportgroup = "resource-mgmt" #Portgroup naam voor Resource Management
    subnetmask = "255.255.255.0" #SubnetMask voor alle Subnets
    vsangateway ="" #Gateway adres voor vSAN
    esxiuser = "root"
    esxipass = "VMware1!" #Lokale root ESXi password
}