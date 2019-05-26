@{
    vcenter = "" #Naam van de vCenter
    vcenteruser = "administrator@vsphere.local"
    vcenterpass = "" #Password voor administrator@vsphere.local
    ntpserver = "" #Ip Adress van de NTP Server
    dasisolation1 = "" #DAS Isolation IP 1
    dasisolation2 = "" #DAS Isolation IP 2
    datacenter = "" #Naam van het Datacenter Object
    cluster = "" #Naam van het CLuster Object
    dvs = "" #Naam van de Distributed Virtual Switch
    rscmgmtvlan = "" #VLAN Resource Management
    vmotionvlan = "" #VLAN vMotion
    provisioningvlan = "" #VLAN Provisioning
    vsanvlan = "" #VLAN vSAN
    vsanportgroup = "" #Portgroup naam voor vSAN
    vmotionportgroup = "" #Portgroup naam voor vMotion
    provisioningportgroup = "" #Portgroup naam voor Provisioning
    resourcemgmtportgroup = "" #Portgroup naam voor Resource Management
    subnetmask = "255.255.255.0" #SubnetMask voor alle Subnets
    vsangateway ="" #Gateway adres voor vSAN
    esxiuser = "root"
    esxipass = "" #Lokale root ESXi password
}