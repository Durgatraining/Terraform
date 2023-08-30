resource "azurerm_resource_group" "CareerIT" {
  name     = "CareerIT_Resource"
  location = "West Europe"
}

resource "azurerm_virtual_network" "VirtualNetwork" {
  name                = "Virtual_Network"
  address_space       = ["10.0.0.0/16"]
  location            = "West Europe"
  resource_group_name = "CareerIT_Resource"
  depends_on = [
     azurerm_resource_group.CareerIT
      ]
}

resource "azurerm_subnet" "Subnet" {
  name                 = "Internal_Subnet"
  resource_group_name  = "CareerIT_Resource"
  virtual_network_name = "Virtual_Network"
  address_prefixes     = ["10.0.2.0/24"]
  depends_on = [ 
    azurerm_virtual_network.VirtualNetwork 
    ]
}

resource "azurerm_network_interface" "NIC" {
  name                = "My_NIC"
  location            = "West Europe"
  resource_group_name = "CareerIT_Resource"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.Subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [ 
    azurerm_subnet.Subnet
     ]
}

resource "azurerm_linux_virtual_machine" "Virtualmachine" {
  name                = "Virtual_Machine"
  resource_group_name = "CareerIT_Resource"
  location            = "West Europe"
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.NIC.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  depends_on = [
     azurerm_network_interface.NIC
      ]
}

