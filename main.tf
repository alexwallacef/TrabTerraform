terraform {
  required_version = ">= 0.14.9"
  
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

resource "azurerm_resource_group" "as02-rg" {
    name     = "rg"
    location = "eastus"
  }

  resource "azurerm_subnet" "as02-subnet" {
    name                  = "subnet"
    resource_group_name   = azurerm_resource_group.as02-rg.name
    virtual_network_name  = azurerm_virtual_network.as02-vnet.name
    address_prefixes       = ["10.0.1.0/24"]
  }

  resource "azurerm_virtual_network" "as02-vnet" {
    name                 = "vnet"
    location             = azurerm_resource_group.as02-rg.location
    resource_group_name  = azurerm_resource_group.as02-rg.name
    address_space        = ["10.0.0.0/16"]

    tags = {
      turma = "as02"
    } 
  }

resource "azurerm_network_security_group" "as02-nsg" {
  name                = "nsg"
  location            = azurerm_resource_group.as02-rg.location
  resource_group_name = azurerm_resource_group.as02-rg.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_public_ip" "as02-ip" {
  name                = "publicip"
  resource_group_name = azurerm_resource_group.as02-rg.name
  location            = azurerm_resource_group.as02-rg.location
  allocation_method   = "Static"
  
}

resource "azurerm_network_interface" "as02-ni" {
  name                = "nic"
  location            = azurerm_resource_group.as02-rg.location
  resource_group_name = azurerm_resource_group.as02-rg.name

  ip_configuration {
    name                          = "ipvm"
    subnet_id                     = azurerm_subnet.as02-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.as02-ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "as02-nicnsg" {
  network_interface_id      = azurerm_network_interface.as02-ni.id
  network_security_group_id = azurerm_network_security_group.as02-nsg.id
}

resource "azurerm_linux_virtual_machine" "as02-vm" {
  name                = "virtualmachine"
  resource_group_name = azurerm_resource_group.as02-rg.name
  location            = azurerm_resource_group.as02-rg.location
  size                = "Standard_DS1_V2"
  admin_username      = "adminuser"
  admin_password      = "adminuser@as02"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.as02-ni.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_mysql_server" "example" {
  name                = "mysqlserver"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  administrator_login          = "mysqladminun"
  administrator_login_password = "H@Sh1CoR3!"

  sku_name   = "B_Gen5_2"
  storage_mb = 5120
  version    = "5.7"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = true
  infrastructure_encryption_enabled = true
  public_network_access_enabled     = false
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"
}

resource "azurerm_mysql_database" "as02" {
  name                = "as02ledb"
  resource_group_name = azurerm_resource_group.exemple.name
  server_name         = azurerm_mysql_server.example.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}