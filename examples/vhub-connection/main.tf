module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "westeurope"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "network" {
  source  = "codectl/vnet/azure"
  version = "~> 1.0"


  vnet = {
    name                = module.naming.virtual_network.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    address_space       = ["10.19.0.0/16"]

    subnets = {
      sn1 = {
        network_security_group = {}
        address_prefixes       = ["10.19.1.0/24"]
      }
    }
  }
}

module "rg_vwan" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  providers = {
    azurerm = azurerm.connectivity
  }

  groups = {
    vwan = {
      name     = "${module.naming.resource_group.name_unique}1"
      location = "westeurope"
    }
  }
}

module "vwan" {
  source  = "codectl/vwan/azure"
  version = "~> 1.0"

  providers = {
    azurerm = azurerm.connectivity
  }


  vwan = {
    name                           = module.naming.virtual_wan.name
    resource_group_name            = module.rg_vwan.groups.vwan.name
    location                       = module.rg_vwan.groups.vwan.location
    allow_branch_to_branch_traffic = true
    disable_vpn_encryption         = false


    vhubs = {
      weu = {
        location       = "westeurope"
        address_prefix = "10.0.0.0/23"
      }
    }
  }
}

module "vhub-connection" {
  source  = "codectl/vwan/azure//modules/vhub-connection"
  version = "~> 1.0"

  providers = {
    azurerm = azurerm.connectivity
  }

  virtual_hub = {
    resource_group_name = module.vwan.vwan.resource_group_name
    name                = module.vwan.vhubs.weu.name

    connections = {
      prod = {
        name                      = "vhcon-demo-prod-weu"
        remote_virtual_network_id = module.network.vnet.id
        internet_security_enabled = false
      }
    }
  }
}
