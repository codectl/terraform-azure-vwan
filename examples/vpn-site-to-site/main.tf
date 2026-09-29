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

module "kv" {
  source  = "codectl/kv/azure"
  version = "~> 1.0"

  vault = {
    name                = module.naming.key_vault.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name

    secrets = {
      random_string = {
        psk = {
          length      = 32
          special     = false
          min_special = 0
          min_upper   = 2
        }
      }
    }
  }
}

module "firewall" {
  source  = "codectl/fw/azure"
  version = "~> 1.0"

  resource_group_name = module.rg.groups.demo.name

  firewall = {
    name     = module.naming.firewall.name
    location = module.rg.groups.demo.location

    sku_name = "AZFW_Hub"
    sku_tier = "Standard"
    virtual_hub = {
      virtual_hub_id = module.vwan.vhubs.weu.id
    }
  }
}

module "vwan" {
  source  = "codectl/vwan/azure"
  version = "~> 1.0"

  location            = module.rg.groups.demo.location
  resource_group_name = module.rg.groups.demo.name

  vwan = {
    name                           = module.naming.virtual_wan.name
    vhubs                          = local.vhubs
    allow_branch_to_branch_traffic = true
    disable_vpn_encryption         = false
  }
}
