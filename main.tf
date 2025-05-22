# main.tf - Core Kubernetes cluster and node pool configuration

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.34.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11.0"
    }
  }
}

# Data sources for available options
data "digitalocean_kubernetes_versions" "available" {
  version_prefix = var.kubernetes_version_prefix
}

data "digitalocean_sizes" "available" {
  filter {
    key    = "regions"
    values = [var.region]
  }
}

# VPC for the cluster
resource "digitalocean_vpc" "cluster_vpc" {
  count = var.create_vpc ? 1 : 0

  name     = "${var.cluster_name}-vpc"
  region   = var.region
  ip_range = var.vpc_cidr
  
  description = "VPC for ${var.cluster_name} Kubernetes cluster"
}

# Local values for cluster configuration
locals {
  vpc_uuid = var.create_vpc ? digitalocean_vpc.cluster_vpc[0].id : var.existing_vpc_uuid
  
  # Determine the latest available Kubernetes version if not specified
  kubernetes_version = var.kubernetes_version != "" ? var.kubernetes_version : data.digitalocean_kubernetes_versions.available.latest_version
  
  # Common tags
  common_tags = merge(
    var.tags,
    {
      "managed-by"    = "terraform"
      "cluster-name"  = var.cluster_name
      "module"        = "terraform-digitalocean-k8s"
    }
  )
  
  # Process node pools with defaults
  processed_node_pools = [
    for pool in var.node_pools : {
      name       = pool.name
      size       = pool.size
      node_count = pool.node_count
      min_nodes  = try(pool.min_nodes, pool.node_count)
      max_nodes  = try(pool.max_nodes, pool.node_count)
      auto_scale = try(pool.auto_scale, false)
      labels     = try(pool.labels, {})
      taints = try(pool.taints, [])
      tags   = concat(
        try(pool.tags, []),
        [var.cluster_name, "k8s-node"]
      )
    }
  ]
}

# Main Kubernetes cluster
resource "digitalocean_kubernetes_cluster" "cluster" {
  name     = var.cluster_name
  region   = var.region
  version  = local.kubernetes_version
  vpc_uuid = local.vpc_uuid

  # Cluster configuration
  auto_upgrade      = var.auto_upgrade
  surge_upgrade     = var.surge_upgrade
  ha               = var.ha_control_plane
  registry_integration = var.enable_registry_integration

  # Maintenance window
  dynamic "maintenance_policy" {
    for_each = var.maintenance_policy != null ? [var.maintenance_policy] : []
    content {
      start_time = maintenance_policy.value.start_time
      day        = maintenance_policy.value.day
    }
  }

  # Default node pool (required by DigitalOcean)
  node_pool {
    name       = "${var.cluster_name}-default"
    size       = var.default_node_pool.size
    node_count = var.default_node_pool.node_count
    auto_scale = var.default_node_pool.auto_scale
    min_nodes  = var.default_node_pool.min_nodes
    max_nodes  = var.default_node_pool.max_nodes
    tags       = concat(var.default_node_pool.tags, [var.cluster_name, "k8s-node", "default-pool"])
    labels     = merge(var.default_node_pool.labels, { "node-pool" = "default" })

    # Taints for default node pool
    dynamic "taint" {
      for_each = var.default_node_pool.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }

  tags = values(local.common_tags)

  # Prevent destruction of cluster
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      # Ignore changes to tags that might be applied externally
      tags,
      # Allow DigitalOcean to manage the default node pool
      node_pool[0].node_count,
    ]
  }

  timeouts {
    create = "30m"
  }
}

# Additional node pools
resource "digitalocean_kubernetes_node_pool" "additional_pools" {
  for_each = { for pool in local.processed_node_pools : pool.name => pool }

  cluster_id = digitalocean_kubernetes_cluster.cluster.id
  name       = each.value.name
  size       = each.value.size
  node_count = each.value.node_count
  auto_scale = each.value.auto_scale
  min_nodes  = each.value.auto_scale ? each.value.min_nodes : null
  max_nodes  = each.value.auto_scale ? each.value.max_nodes : null
  
  tags   = each.value.tags
  labels = merge(each.value.labels, { "node-pool" = each.value.name })

  # Node pool taints
  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  timeouts {
    create = "30m"
    delete = "30m"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      # Allow auto-scaling to manage node count
      node_count,
    ]
  }
}

# Cluster firewall
resource "digitalocean_firewall" "cluster_firewall" {
  count = var.create_firewall ? 1 : 0

  name = "${var.cluster_name}-firewall"
  tags = [var.cluster_name]

  # Allow inbound traffic on common ports
  dynamic "inbound_rule" {
    for_each = var.firewall_rules
    content {
      protocol                  = inbound_rule.value.protocol
      port_range               = inbound_rule.value.port_range
      source_addresses         = try(inbound_rule.value.source_addresses, [])
      source_load_balancer_uids = try(inbound_rule.value.source_load_balancer_uids, [])
      source_tags              = try(inbound_rule.value.source_tags, [])
      source_droplet_ids       = try(inbound_rule.value.source_droplet_ids, [])
    }
  }

  # Default outbound rules (allow all)
  outbound_rule {
    protocol              = "tcp"
    port_range           = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range           = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# Container Registry (optional)
resource "digitalocean_container_registry" "cluster_registry" {
  count = var.create_container_registry ? 1 : 0

  name                   = "${var.cluster_name}-registry"
  subscription_tier_slug = var.registry_subscription_tier
  region                 = var.region
}

# Registry integration with cluster
resource "digitalocean_container_registry_docker_credentials" "cluster_registry_creds" {
  count = var.create_container_registry ? 1 : 0

  registry_name = digitalocean_container_registry.cluster_registry[0].name
  write         = var.registry_write_access

  depends_on = [digitalocean_container_registry.cluster_registry]
}

# Project organization (optional)
resource "digitalocean_project" "cluster_project" {
  count = var.create_project ? 1 : 0

  name        = var.project_name != "" ? var.project_name : "${var.cluster_name}-project"
  description = "Resources for ${var.cluster_name} Kubernetes cluster"
  purpose     = "Kubernetes cluster and related resources"
  environment = var.environment

  resources = concat(
    [digitalocean_kubernetes_cluster.cluster.urn],
    var.create_vpc ? [digitalocean_vpc.cluster_vpc[0].urn] : [],
    var.create_container_registry ? [digitalocean_container_registry.cluster_registry[0].urn] : [],
    var.create_firewall ? [digitalocean_firewall.cluster_firewall[0].urn] : []
  )
}

# Data source to get cluster credentials for provider configuration
data "digitalocean_kubernetes_cluster" "cluster" {
  name = digitalocean_kubernetes_cluster.cluster.name
  
  depends_on = [digitalocean_kubernetes_cluster.cluster]
}

# Configure Kubernetes provider
provider "kubernetes" {
  host  = data.digitalocean_kubernetes_cluster.cluster.endpoint
  token = data.digitalocean_kubernetes_cluster.cluster.kube_config[0].token
  cluster_ca_certificate = base64decode(
    data.digitalocean_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate
  )
}

# Configure Helm provider
provider "helm" {
  kubernetes {
    host  = data.digitalocean_kubernetes_cluster.cluster.endpoint
    token = data.digitalocean_kubernetes_cluster.cluster.kube_config[0].token
    cluster_ca_certificate = base64decode(
      data.digitalocean_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate
    )
  }
}