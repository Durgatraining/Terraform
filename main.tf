resource "azurerm_resource_group" "terraform" {
    name                              = var.resource_group_details.name
    location                          = var.resource_group_details.location
}

resource "azurerm_virtual_network" "virtualnetwork" {
  name                                = "virtualnetwork"
  location                            = var.resource_group_details.location
  resource_group_name                 = var.resource_group_details.name
  address_space                       = var.addressspace
  depends_on = [
    azurerm_resource_group.terraform
  ]
  } 

  resource "" "name" {
    
  }
  resource "azurerm_subnet" "subnet1" {
  count                               = length(var.subnet_details)
  name                                = var.subnet_details[count.index]
  resource_group_name                 = var.resource_group_details.name
  virtual_network_name                = "virtualnetwork"
  address_prefixes                    = [ cidrsubnet(var.addressspace[0], 8, count.index) ]
  depends_on = [ 
    azurerm_virtual_network.virtualnetwork
   ]
}

resource "azurerm_public_ip" "publicip" {
    count                             = length(var.publicip) 
    name                              = var.publicip[count.index]
    resource_group_name               = var.resource_group_details.name
    location                          = var.resource_group_details.location
    allocation_method                 = "Dynamic"

    depends_on = [
      azurerm_resource_group.terraform
    ]

}

resource "azurerm_network_security_group" "netsecgroup" {
  name                                = var.netsecgroup
  location                            = var.resource_group_details.location
  resource_group_name                 = var.resource_group_details.name

  security_rule {
    name                              = "test123"
    priority                          = 100
    direction                         = "Inbound"
    access                            = "Allow"
    protocol                          = "Tcp"
    source_port_range                 = "*"
    destination_port_range            = "*"
    source_address_prefix             = "*"
    destination_address_prefix        = "*"
  }

  tags = {
    environment = "Production"
  }
  depends_on = [
    azurerm_resource_group.terraform
  ]
}

resource "azurerm_network_interface" "networkinterface" {
  count                               = length(var.nic)
  name                                = var.nic[count.index]
  location                            = var.resource_group_details.location
  resource_group_name                 = var.resource_group_details.name

  ip_configuration {
    name                              = "testconfiguration"
    subnet_id                         = azurerm_subnet.subnet1[count.index].id
    private_ip_address_allocation     = "Dynamic"
  }
  depends_on = [
    azurerm_resource_group.terraform,
    azurerm_public_ip.publicip,
    azurerm_subnet.subnet1
  ]
}

resource "azurerm_network_interface_security_group_association" "nisga" {
  count                               = length(var.nic)
  network_interface_id                = azurerm_network_interface.networkinterface[count.index].id
  network_security_group_id           = azurerm_network_security_group.netsecgroup.id

  depends_on = [
    azurerm_network_security_group.netsecgroup
  ]
}

resource "azurerm_virtual_machine" "virtualmachine" {
  count = length(var.vms)
  #count = terraform.workspace == "dev" ? 1 : 0
  name                                = var.vms[count.index]
  location                            = var.resource_group_details.location
  resource_group_name                 = var.resource_group_details.name
  network_interface_ids               = [azurerm_network_interface.networkinterface[count.index].id]
  vm_size                             = "Standard_DS1_v2"
  storage_image_reference {
    publisher                         = "Canonical"
    offer                             = "0001-com-ubuntu-server-focal"
    sku                               = "20_04-lts-gen2"
    version                           = "latest"
  }
  storage_os_disk {
    name                              = var.disk_names[count.index]
    caching                           = "ReadWrite"
    create_option                     = "FromImage"
    managed_disk_type                 = "Standard_LRS"
  }
  os_profile {
    computer_name                     = "hostname"
    admin_username                    = var.usern
    admin_password                    = var.pass
  }
 os_profile_linux_config {
    disable_password_authentication   = false
  }

  tags = {
    environment = "staging"
  }
  depends_on = [
    azurerm_network_interface_security_group_association.nisga
  ]
}
