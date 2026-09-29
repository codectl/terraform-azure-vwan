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

module "vhub_route_tables" {
  source  = "codectl/vwan/azure//modules/vhub-route-table"
  version = "~> 1.0"

  route_tables = local.route_tables
}
