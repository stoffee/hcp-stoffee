// Pin the version
terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.7.0"
    }
  }
}

// Configure the provider
provider "hcp" {}

// Use the cloud provider AWS to provision resources that will be connected to HCP
provider "aws" {
  region = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

// Create an HVN
resource "hcp_hvn" "my_hvn" {
  hvn_id         = "hcp-hvn-${var.prefix}"
  cloud_provider = "aws"
  region         = var.region
  cidr_block     = "172.25.16.0/20"
}

// Create a VPC for the HVN to peer into
resource "aws_vpc" "main" {
  cidr_block = "172.25.0.0/20"
}

data "aws_arn" "main" {
  arn = aws_vpc.main.arn
}

resource "aws_vpc_peering_connection_accepter" "main" {
  vpc_peering_connection_id = hcp_aws_network_peering.example_peering.provider_peering_id
  auto_accept               = true
}

// Create a network peering between the HVN and the AWS VPC
resource "hcp_aws_network_peering" "hvn_peering" {
  hvn_id          = hcp_hvn.my_hvn.hvn_id
  peering_id      = "hcp-${var.prefix}-peering"
  peer_vpc_id     = aws_vpc.main.id
  peer_account_id = aws_vpc.main.owner_id
  peer_vpc_region = data.aws_arn.main.region
}

// Create an HVN route that targets your HCP network peering and matches your AWS VPC's CIDR block
resource "hcp_hvn_route" "hvn_route" {
  hvn_link         = hcp_hvn.hvn.self_link
  hvn_route_id     = "hcp-${var.stoffee}-hvn-route"
  destination_cidr = aws_vpc.main.cidr_block
  target_link      = hcp_aws_network_peering.example.self_link
}

// Create a Consul cluster in the same region and cloud provider as the HVN
resource "hcp_consul_cluster" "hcp_consul" {
  hvn_id     = hcp_hvn.my_hvn.hvn_id
  cluster_id = "hcp-${var.prefix}-consul-cluster"
  tier       = "development"
}

// Create a Vault cluster in the same region and cloud provider as the HVN
resource "hcp_vault_cluster" "hcp_vault" {
  cluster_id = "hcp-${var.prefix}-vault-cluster"
  hvn_id     = hcp_hvn.my_hvn.hvn_id
}
