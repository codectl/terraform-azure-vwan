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

  location            = module.rg.groups.demo.location
  resource_group_name = module.rg.groups.demo.name

  vwan = {
    name                           = module.naming.virtual_wan.name
    vhubs                          = local.vhubs
    allow_branch_to_branch_traffic = true
    disable_vpn_encryption         = false
  }
}

module "firewall" {
  source  = "codectl/fw/azure"
  version = "~> 1.0"

  resource_group_name = module.rg.groups.demo.name
  for_each            = local.firewalls

  firewall = each.value
}

module "fw_policy" {
  source  = "codectl/fwp/azure"
  version = "~> 1.0"

  resource_group_name = module.rg.groups.demo.name
  location            = module.rg.groups.demo.location

  firewall_policy = {
    name                     = module.naming.firewall_policy.name
    threat_intelligence_mode = "Alert"
  }
}

module "collection_rule_groups" {
  source  = "codectl/fwp/azure//modules/collection-rule-groups"
  version = "~> 1.0"

  groups = local.collection_rule_groups
}

locals {
  collection_rule_groups = {
    default = {
      priority           = 1000
      firewall_policy_id = module.fw_policy.firewall_policy.id
      network_rule_collections = {
        allow_internal = {
          name     = "allow-internal-traffic"
          priority = 1000
          action   = "Allow"
          rules = {
            allow_vnet_to_vnet = {
              protocols             = ["TCP", "UDP"]
              destination_ports     = ["*"]
              destination_addresses = ["10.0.0.0/8"]
              source_addresses      = ["10.0.0.0/8"]
            }
          }
        }
      }
      application_rule_collections = {
        allow_microsoft = {
          name     = "allow-microsoft-services"
          priority = 2000
          action   = "Allow"
          rules = {
            allow_microsoft_com = {
              source_addresses  = ["10.0.0.0/8"]
              destination_fqdns = ["*.microsoft.com", "*.azure.com"]
              protocols = [
                {
                  type = "Https"
                  port = 443
                }
              ]
            }
          }
        }
      }
    }
  }
}
