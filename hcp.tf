resource "hcp_hvn" "hvn" {
  hvn_id         = "${var.prefix}hvn"
  cloud_provider = "aws"
  region         = var.region
  cidr_block     = "172.25.16.0/20"
}

resource "aws_vpc_peering_connection_accepter" "main" {
  vpc_peering_connection_id = hcp_aws_network_peering.peer.provider_peering_id
  auto_accept               = true
}

resource "hcp_hvn_route" "hvn_route" {
  hvn_link         = hcp_hvn.hvn.self_link
  hvn_route_id     = "${var.prefix}vpc-route"
  destination_cidr = module.vpc.vpc_cidr_block
  target_link      = hcp_aws_network_peering.peer.self_link
}
resource "hcp_aws_network_peering" "peer" {
  hvn_id          = hcp_hvn.hvn.hvn_id
  peering_id      = "${var.prefix}peering"
  peer_vpc_id     = module.vpc.vpc_id
  peer_account_id = module.vpc.vpc_owner_id
  peer_vpc_region = var.region
}

resource "aws_route" "hcp_route" {
  for_each = toset(concat(
    module.vpc.private_route_table_ids,
    module.vpc.public_route_table_ids,
    module.vpc.intra_route_table_ids,
    module.vpc.database_route_table_ids,
    module.vpc.elasticache_route_table_ids,
    module.vpc.redshift_route_table_ids,
  ))
  route_table_id            = each.value
  destination_cidr_block    = hcp_hvn.hvn.cidr_block
  vpc_peering_connection_id = hcp_aws_network_peering.peer.provider_peering_id
}

resource "hcp_vault_cluster" "vault" {
  cluster_id      = "${var.prefix}vault-cluster"
  hvn_id          = hcp_hvn.hvn.hvn_id
  tier            = "dev"
  public_endpoint = true
}