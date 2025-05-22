# variables.tf - Input variables for the Kubernetes cluster module

# Cluster Configuration
variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.cluster_name)) && length(var.cluster_name) <= 63
    error_message = "Cluster name must contain only lowercase letters, numbers, and hyphens, and be no longer than 63 characters."
  }
}

variable "region" {
  description = "DigitalOcean region for the cluster"
  type        = string
  default     = "nyc3"
  
  validation {
    condition = contains([
      "nyc1", "nyc3", "ams3", "sfo3", "sgp1", "lon1", 
      "fra1", "tor1", "blr1", "syd1"
    ], var.region)
    error_message = "Region must be a valid DigitalOcean region."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the cluster"
  type        = string
  default     = ""
}

variable "kubernetes_version_prefix" {
  description = "Kubernetes version prefix to filter available versions"
  type        = string
  default     = "1.28"
}

variable "auto_upgrade" {
  description = "Enable automatic upgrades for the cluster"
  type        = bool
  default     = false
}

variable "surge_upgrade" {
  description = "Enable surge upgrades for faster updates"
  type        = bool
  default     = true
}

variable "ha_control_plane" {
  description = "Enable high availability for the control plane"
  type        = bool
  default     = false
}

variable "enable_registry_integration" {
  description = "Enable DigitalOcean Container Registry integration"
  type        = bool
  default     = true
}

# Maintenance Configuration
variable "maintenance_policy" {
  description = "Maintenance policy for the cluster"
  type = object({
    start_time = string
    day        = string
  })
  default = null
  
  validation {
    condition = var.maintenance_policy == null || (
      can(regex("^([01]?[0-9]|2[0-3]):[0-5][0-9]$", var.maintenance_policy.start_time)) &&
      contains(["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"], lower(var.maintenance_policy.day))
    )
    error_message = "Maintenance policy start_time must be in HH:MM format and day must be a valid day of the week."
  }
}

# Default Node Pool Configuration
variable "default_node_pool" {
  description = "Configuration for the default node pool"
  type = object({
    size       = string
    node_count = number
    auto_scale = bool
    min_nodes  = number
    max_nodes  = number
    labels     = map(string)
    tags       = list(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  })
  default = {
    size       = "s-2vcpu-4gb"
    node_count = 2
    auto_scale = true
    min_nodes  = 1
    max_nodes  = 5
    labels     = {}
    tags       = []
    taints     = []
  }
}

# Additional Node Pools
variable "node_pools" {
  description = "List of additional node pools to create"
  type = list(object({
    name       = string
    size       = string
    node_count = number
    auto_scale = optional(bool, false)
    min_nodes  = optional(number)
    max_nodes  = optional(number)
    labels     = optional(map(string), {})
    tags       = optional(list(string), [])
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = []
  
  validation {
    condition = alltrue([
      for pool in var.node_pools : 
      can(regex("^[a-z0-9-]+$", pool.name)) && length(pool.name) <= 63
    ])
    error_message = "Node pool names must contain only lowercase letters, numbers, and hyphens, and be no longer than 63 characters."
  }
}

# Network Configuration
variable "create_vpc" {
  description = "Create a new VPC for the cluster"
  type        = bool
  default     = true
}

variable "existing_vpc_uuid" {
  description = "UUID of existing VPC to use (required if create_vpc is false)"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

# Firewall Configuration
variable "create_firewall" {
  description = "Create firewall rules for the cluster"
  type        = bool
  default     = true
}

variable "firewall_rules" {
  description = "List of firewall rules for the cluster"
  type = list(object({
    protocol                  = string
    port_range               = string
    source_addresses         = optional(list(string), [])
    source_load_balancer_uids = optional(list(string), [])
    source_tags              = optional(list(string), [])
    source_droplet_ids       = optional(list(number), [])
  }))
  default = [
    {
      protocol         = "tcp"
      port_range      = "80"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range      = "443"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range      = "22"
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  ]
}

# Container Registry Configuration
variable "create_container_registry" {
  description = "Create a DigitalOcean Container Registry"
  type        = bool
  default     = false
}

variable "registry_subscription_tier" {
  description = "Container registry subscription tier"
  type        = string
  default     = "basic"
  
  validation {
    condition     = contains(["starter", "basic", "professional"], var.registry_subscription_tier)
    error_message = "Registry subscription tier must be one of: starter, basic, professional."
  }
}

variable "registry_write_access" {
  description = "Enable write access to the container registry"
  type        = bool
  default     = true
}

# Project Configuration
variable "create_project" {
  description = "Create a DigitalOcean project for organizing resources"
  type        = bool
  default     = false
}

variable "project_name" {
  description = "Name of the DigitalOcean project"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment for the project (Development, Staging, Production)"
  type        = string
  default     = "Development"
  
  validation {
    condition     = contains(["Development", "Staging", "Production"], var.environment)
    error_message = "Environment must be one of: Development, Staging, Production."
  }
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Enable monitoring stack (Prometheus, Grafana)"
  type        = bool
  default     = false
}

variable "monitoring_config" {
  description = "Configuration for monitoring stack"
  type = object({
    prometheus = optional(object({
      enabled        = optional(bool, true)
      retention_days = optional(number, 15)
      storage_size   = optional(string, "20Gi")
      scrape_interval = optional(string, "30s")
    }), {})
    grafana = optional(object({
      enabled            = optional(bool, true)
      admin_password     = optional(string, "admin")
      persistence_enabled = optional(bool, true)
      storage_size       = optional(string, "10Gi")
    }), {})
    alertmanager = optional(object({
      enabled        = optional(bool, false)
      storage_size   = optional(string, "5Gi")
    }), {})
  })
  default = {}
}

# Logging Configuration
variable "enable_logging" {
  description = "Enable centralized logging"
  type        = bool
  default     = false
}

variable "logging_config" {
  description = "Configuration for logging stack"
  type = object({
    log_level      = optional(string, "info")
    retention_days = optional(number, 7)
    audit_logs     = optional(bool, false)
    destinations = optional(list(object({
      type     = string
      endpoint = optional(string, "")
      bucket   = optional(string, "")
    })), [])
  })
  default = {}
}

# Backup Configuration
variable "enable_backup" {
  description = "Enable automated backups"
  type        = bool
  default     = false
}

variable "backup_config" {
  description = "Configuration for backup system"
  type = object({
    schedule         = optional(string, "0 2 * * *")
    retention_days   = optional(number, 7)
    include_resources = optional(list(string), [
      "persistentvolumes",
      "persistentvolumeclaims",
      "secrets",
      "configmaps"
    ])
    storage_location = optional(object({
      type   = string
      bucket = string
      region = optional(string, "")
    }), null)
  })
  default = {}
}

# Add-ons Configuration
variable "addons" {
  description = "Configuration for cluster add-ons"
  type = object({
    ingress_nginx = optional(object({
      enabled       = optional(bool, false)
      version      = optional(string, "4.7.1")
      replica_count = optional(number, 2)
      config       = optional(map(any), {})
    }), {})
    cert_manager = optional(object({
      enabled = optional(bool, false)
      version = optional(string, "v1.13.0")
      email   = optional(string, "")
      config  = optional(map(any), {})
    }), {})
    argocd = optional(object({
      enabled        = optional(bool, false)
      version       = optional(string, "5.46.0")
      admin_password = optional(string, "")
      config        = optional(map(any), {})
    }), {})
    istio = optional(object({
      enabled = optional(bool, false)
      version = optional(string, "1.19.0")
      config  = optional(map(any), {})
    }), {})
    external_dns = optional(object({
      enabled = optional(bool, false)
      version = optional(string, "1.13.1")
      provider = optional(string, "digitalocean")
      config  = optional(map(any), {})
    }), {})
  })
  default = {}
}

# Storage Configuration
variable "enable_csi" {
  description = "Enable Container Storage Interface (CSI)"
  type        = bool
  default     = true
}

variable "default_storage_class" {
  description = "Default storage class for the cluster"
  type        = string
  default     = "do-block-storage"
}

variable "storage_classes" {
  description = "Additional storage classes to create"
  type = list(object({
    name            = string
    provisioner     = string
    parameters      = map(string)
    reclaim_policy  = optional(string, "Delete")
    allow_volume_expansion = optional(bool, true)
  }))
  default = []
}

# Tags
variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}

# Debug and Development
variable "debug_mode" {
  description = "Enable debug mode for troubleshooting"
  type        = bool
  default     = false
}