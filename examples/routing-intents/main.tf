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

module "vwan" {
  source  = "codectl/vwan/azure"
  version = "~> 1.0"

  vwan = {
    name                           = module.naming.virtual_wan.name
    resource_group_name            = module.rg.groups.demo.name
    location                       = module.rg.groups.demo.location
    vhubs                          = local.vhubs
    allow_branch_to_branch_traffic = true
    disable_vpn_encryption         = false
  }
}

module "routing_intents" {
  source  = "codectl/vwan/azure//modules/routing-intent"
  version = "~> 1.0"

  configs = {
    weu = {
      virtual_hub_id = module.vwan.vhubs.weu.id
      routing_policies = {
        internet_policy = {
          destinations = ["Internet"]
          next_hop     = module.firewall.weu.firewall.id
        }
      }
    }
    sea = {
      virtual_hub_id = module.vwan.vhubs.sea.id
      routing_policies = {
        internet_policy = {
          destinations = ["Internet"]
          next_hop     = module.firewall.sea.firewall.id
        }
      }
    }
  }
}

module "firewall" {
  source  = "codectl/fw/azure"
  version = "~> 1.0"

  resource_group_name = module.rg.groups.demo.name
  for_each            = local.firewalls

  firewall = each.value
}
