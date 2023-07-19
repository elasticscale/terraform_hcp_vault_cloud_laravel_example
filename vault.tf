resource "hcp_vault_cluster" "vault" {
  cluster_id      = "${var.prefix}vault-cluster"
  hvn_id          = hcp_hvn.hvn.hvn_id
  tier            = "dev"
  public_endpoint = true
}