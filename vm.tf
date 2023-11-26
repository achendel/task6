resource "azurerm_resource_group" "example" {
  name     = "akshatha_t5"
  location = "Canada Central"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_public_ip" "example" {
  name                = "plt_pub_id"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}
data "azurerm_public_ip" "public_ip" {
  name                = azurerm_public_ip.example.name
  resource_group_name = azurerm_resource_group.example.name
}
resource "azurerm_network_security_group" "example" {
  name                = "sec_gro"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name


  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = {
    environment = "Production"
  }
}



resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("jj.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  // custom_data = base64encode(file("install.sh"))
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  provisioner "file" {

    source      = "script.sh"
    destination = "/home/adminuser/script.sh"
 
 }
 provisioner "remote-exec" {
    
    inline = [
      "ls -lh",
       "chmod 777 ./script.sh",
       "sudo ./script.sh ${azurerm_public_ip.example.ip_address}",
   ]
  }
  provisioner "local-exec" {
    command = "echo ${azurerm_public_ip.example.ip_address} >> local.txt"
  }
connection {
    type        = "ssh"
    user        = "adminuser"
    host        = azurerm_public_ip.example.ip_address
    private_key = file("jj")
  }
 
  # testing the pipeline.
  # testing the pipeline.

}  



