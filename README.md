# Terraform DigitalOcean Kubernetes Module

A comprehensive, production-ready Terraform module for deploying and managing Kubernetes clusters on DigitalOcean with best practices, security configurations, and extensible architecture.

## 🏗️ Architecture Overview

This module creates a complete Kubernetes infrastructure on DigitalOcean with the following architecture:

```
┌─────────────────────────────────────────────────────────────────┐
│                    DigitalOcean Region                          │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                      VPC                                │    │
│  │                                                         │    │
│  │  ┌─────────────────────────────────────────────────┐    │    │
│  │  │            Kubernetes Cluster                   │    │    │
│  │  │                                                 │    │    │
│  │  │  ┌─────────────┐  ┌─────────────┐               │     │   │
│  │  │  │ Control     │  │ Worker      │               │     │   │
│  │  │  │ Plane       │  │ Node Pool   │               │     │   │
│  │  │  │ (Managed)   │  │             │               │     │   │
│  │  │  └─────────────┘  └─────────────┘               │     │   │
│  │  │                                                 │    │    │
│  │  │  ┌─────────────┐  ┌─────────────┐               │     │   │
│  │  │  │ Additional  │  │ System      │               │     │   │
│  │  │  │ Node Pool   │  │ Node Pool   │               │     │   │
│  │  │  │ (Optional)  │  │ (Optional)  │               │     │   │
│  │  │  └─────────────┘  └─────────────┘               │     │   │
│  │  └─────────────────────────────────────────────────┘    │    │
│  │                                                         │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │    │
│  │  │ LoadBalancer│  │ Firewall    │  │ Database    │      │    │
│  │  │             │  │ Rules       │  │ (Optional)  │      │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ Container   │  │ Volume      │  │ Monitoring  │              │
│  │ Registry    │  │ Storage     │  │ (Optional)  │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Features

### Core Kubernetes Features
- **Managed Control Plane**: Fully managed Kubernetes control plane by DigitalOcean
- **Multiple Node Pools**: Support for multiple node pools with different configurations
- **Auto-scaling**: Horizontal Pod Autoscaler and Cluster Autoscaler support
- **High Availability**: Multi-AZ deployment for production workloads
- **Version Management**: Automated Kubernetes version updates and maintenance windows

### Networking & Security
- **VPC Integration**: Dedicated Virtual Private Cloud for network isolation
- **Firewall Rules**: Configurable security groups and firewall rules
- **Load Balancer**: Integrated DigitalOcean Load Balancer support
- **Network Policies**: Kubernetes network policies for micro-segmentation
- **TLS/SSL**: Automatic certificate management with cert-manager integration

### Storage & Data
- **Persistent Storage**: DigitalOcean Block Storage integration
- **Container Registry**: Private container registry integration
- **Backup Solutions**: Automated cluster and application backup strategies
- **Database Integration**: Optional managed database services integration

### Monitoring & Observability
- **Metrics Collection**: Prometheus and Grafana integration
- **Logging**: Centralized logging with ELK/EFK stack
- **Alerting**: Configurable alerting rules and notifications
- **Health Checks**: Comprehensive cluster health monitoring

### DevOps & Automation
- **GitOps Ready**: ArgoCD/Flux integration support
- **CI/CD Integration**: GitHub Actions, GitLab CI, and Jenkins compatibility
- **Infrastructure as Code**: Complete Terraform-based deployment
- **Helm Charts**: Pre-configured Helm charts for common applications

## 📋 Prerequisites

Before using this module, ensure you have:

1. **DigitalOcean Account**: Active DigitalOcean account with API access
2. **Terraform**: Version >= 1.5.0
3. **DigitalOcean Provider**: Version >= 2.34.0
4. **kubectl**: For cluster management (optional but recommended)
5. **doctl**: DigitalOcean CLI tool (optional but recommended)

### Required Permissions

Your DigitalOcean API token needs the following scopes:
- `read` and `write` access to Kubernetes clusters
- `read` and `write` access to Droplets
- `read` and `write` access to Load Balancers
- `read` and `write` access to VPCs
- `read` and `write` access to Firewalls
- `read` and `write` access to Block Storage

## 🔧 Module Configuration

### Basic Usage

```hcl
module "k8s_cluster" {
  source = "path/to/terraform-digitalocean-k8s"

  # Cluster Configuration
  cluster_name    = "production-k8s"
  kubernetes_version = "1.28.2-do.0"
  region         = "nyc3"
  
  # Node Pool Configuration
  node_pools = [
    {
      name       = "worker-pool"
      size       = "s-2vcpu-4gb"
      node_count = 3
      min_nodes  = 2
      max_nodes  = 10
      auto_scale = true
      labels = {
        "node-type" = "worker"
        "environment" = "production"
      }
      tags = ["worker", "production"]
    }
  ]

  # Network Configuration
  vpc_cidr = "10.10.0.0/16"
  
  # Tags
  tags = {
    Environment = "production"
    Project     = "my-app"
    Owner       = "platform-team"
  }
}
```

### Advanced Configuration

```hcl
module "k8s_cluster" {
  source = "path/to/terraform-digitalocean-k8s"

  # Cluster Configuration
  cluster_name       = "advanced-k8s"
  kubernetes_version = "1.28.2-do.0"
  region            = "nyc3"
  auto_upgrade      = true
  surge_upgrade     = true
  ha_control_plane  = true

  # Multiple Node Pools
  node_pools = [
    {
      name       = "system-pool"
      size       = "s-2vcpu-4gb"
      node_count = 2
      min_nodes  = 2
      max_nodes  = 4
      auto_scale = true
      labels = {
        "node-type" = "system"
      }
      taints = [
        {
          key    = "node-type"
          value  = "system"
          effect = "NoSchedule"
        }
      ]
      tags = ["system"]
    },
    {
      name       = "compute-pool"
      size       = "c-4"
      node_count = 3
      min_nodes  = 1
      max_nodes  = 20
      auto_scale = true
      labels = {
        "node-type" = "compute"
        "workload"  = "cpu-intensive"
      }
      tags = ["compute", "cpu-optimized"]
    },
    {
      name       = "memory-pool"
      size       = "m-4vcpu-32gb"
      node_count = 2
      min_nodes  = 0
      max_nodes  = 10
      auto_scale = true
      labels = {
        "node-type" = "memory"
        "workload"  = "memory-intensive"
      }
      tags = ["memory", "memory-optimized"]
    }
  ]

  # Network Configuration
  create_vpc           = true
  vpc_cidr            = "10.20.0.0/16"
  enable_private_cluster = false
  
  # Security Configuration
  firewall_rules = [
    {
      type                     = "inbound"
      protocol                = "tcp"
      port_range              = "443"
      source_addresses        = ["0.0.0.0/0", "::/0"]
      source_load_balancer_uids = []
      source_tags             = []
      source_droplet_ids      = []
    },
    {
      type                     = "inbound"
      protocol                = "tcp"
      port_range              = "80"
      source_addresses        = ["0.0.0.0/0", "::/0"]
      source_load_balancer_uids = []
      source_tags             = []
      source_droplet_ids      = []
    }
  ]

  # Storage Configuration
  enable_csi = true
  default_storage_class = "do-block-storage"

  # Monitoring & Logging
  enable_monitoring = true
  monitoring_config = {
    enable_prometheus = true
    enable_grafana   = true
    retention_days   = 30
  }

  enable_logging = true
  logging_config = {
    log_level = "info"
    audit_logs = true
  }

  # Backup Configuration
  enable_backup = true
  backup_config = {
    schedule = "0 2 * * *"  # Daily at 2 AM
    retention_days = 7
  }

  # Add-ons
  addons = {
    ingress_nginx = {
      enabled = true
      version = "4.7.1"
    }
    cert_manager = {
      enabled = true
      version = "v1.13.0"
      email   = "admin@example.com"
    }
    argocd = {
      enabled = true
      version = "5.46.0"
    }
  }

  # Tags
  tags = {
    Environment = "production"
    Project     = "advanced-k8s"
    Owner       = "platform-team"
    Cost-Center = "engineering"
  }
}
```

## 📊 Cluster Specifications

### Supported Kubernetes Versions
- **Latest Stable**: 1.28.x (recommended for production)
- **Previous Stable**: 1.27.x (supported)
- **Legacy**: 1.26.x (deprecated, upgrade recommended)

### Available Node Sizes

| Size | vCPUs | Memory | Storage | Network | Use Case |
|------|-------|--------|---------|---------|----------|
| `s-1vcpu-2gb` | 1 | 2 GB | 25 GB SSD | 1 Gbps | Development/Testing |
| `s-2vcpu-4gb` | 2 | 4 GB | 50 GB SSD | 2 Gbps | Small workloads |
| `s-4vcpu-8gb` | 4 | 8 GB | 100 GB SSD | 4 Gbps | General purpose |
| `c-2` | 2 | 4 GB | 25 GB SSD | 2 Gbps | CPU-optimized |
| `c-4` | 4 | 8 GB | 50 GB SSD | 4 Gbps | CPU-optimized |
| `m-2vcpu-16gb` | 2 | 16 GB | 50 GB SSD | 2 Gbps | Memory-optimized |
| `m-4vcpu-32gb` | 4 | 32 GB | 100 GB SSD | 4 Gbps | Memory-optimized |

### Regional Availability

#### Recommended Regions (High Performance)
- **NYC3** (New York): Low latency for East Coast US
- **LON1** (London): GDPR compliant for EU
- **FRA1** (Frankfurt): EU Central location
- **SGP1** (Singapore): Asia-Pacific hub
- **SFO3** (San Francisco): West Coast US

#### Additional Regions
- **TOR1** (Toronto): Canadian data residency
- **AMS3** (Amsterdam): EU alternative
- **BLR1** (Bangalore): India operations

## 🔐 Security Best Practices

### Network Security
- **Private Networking**: All cluster communication uses private IPs
- **Firewall Configuration**: Restrictive ingress rules, permissive egress
- **Network Policies**: Implement Kubernetes Network Policies for pod-to-pod communication
- **VPC Isolation**: Dedicated VPC for each environment

### Access Control
- **RBAC**: Kubernetes Role-Based Access Control enabled by default
- **Service Accounts**: Dedicated service accounts for workloads
- **API Server Access**: Restricted API server access with IP whitelisting
- **Pod Security Standards**: Enforced pod security policies

### Data Protection
- **Encryption at Rest**: All persistent volumes encrypted
- **Encryption in Transit**: TLS for all communications
- **Secrets Management**: Kubernetes secrets with external secret managers
- **Regular Backups**: Automated cluster and application backups

## 📈 Monitoring and Observability

### Metrics Collection
```hcl
monitoring_config = {
  enable_prometheus = true
  prometheus_config = {
    retention_days = 15
    storage_size   = "20Gi"
    scrape_interval = "30s"
  }
  
  enable_grafana = true
  grafana_config = {
    admin_password = "secure-password"
    persistence_enabled = true
    storage_size = "10Gi"
  }
}
```

### Logging Configuration
```hcl
logging_config = {
  enable_fluentd = true
  log_level     = "info"
  retention_days = 7
  
  destinations = [
    {
      type = "elasticsearch"
      endpoint = "https://elasticsearch.example.com"
    },
    {
      type = "s3"
      bucket = "k8s-logs-bucket"
    }
  ]
}
```

### Alerting Rules
The module includes pre-configured alerting rules for:
- **Cluster Health**: Node status, API server availability
- **Resource Utilization**: CPU, memory, storage usage
- **Application Health**: Pod status, deployment failures
- **Network Issues**: Service connectivity, ingress errors

## 🔄 Backup and Disaster Recovery

### Automated Backups
```hcl
backup_config = {
  enabled = true
  schedule = "0 2 * * *"  # Daily at 2 AM UTC
  retention_days = 30
  
  include_resources = [
    "persistentvolumes",
    "persistentvolumeclaims",
    "secrets",
    "configmaps"
  ]
  
  storage_location = {
    type = "s3"
    bucket = "k8s-backups"
    region = "us-east-1"
  }
}
```

### Disaster Recovery Plan
1. **Cluster Recreation**: Automated cluster recreation from Terraform state
2. **Data Restoration**: Persistent volume restoration from snapshots
3. **Application Deployment**: GitOps-based application redeployment
4. **DNS and Load Balancer**: Automated DNS and load balancer reconfiguration

## 🚀 Getting Started

### Step 1: Clone and Configure
```bash
git clone <module-repository>
cd terraform-digitalocean-k8s

# Copy example configuration
cp examples/basic/main.tf .
cp examples/basic/variables.tf .
cp examples/basic/terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your configuration
```

### Step 2: Initialize and Plan
```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### Step 3: Configure kubectl
```bash
# Get cluster credentials
doctl kubernetes cluster kubeconfig save <cluster-name>

# Verify cluster access
kubectl get nodes
kubectl get pods --all-namespaces
```

### Step 4: Deploy Applications
```bash
# Example: Deploy nginx ingress controller
kubectl apply -f examples/manifests/nginx-ingress.yaml

# Example: Deploy sample application
kubectl apply -f examples/manifests/sample-app.yaml
```

## 🔧 Customization and Extensions

### Custom Node Pool Configuration
```hcl
node_pools = [
  {
    name       = "custom-pool"
    size       = "s-4vcpu-8gb"
    node_count = 5
    
    # Custom labels for workload scheduling
    labels = {
      "workload-type" = "web-servers"
      "zone"         = "dmz"
    }
    
    # Taints to control pod scheduling
    taints = [
      {
        key    = "dedicated"
        value  = "web-servers"
        effect = "NoSchedule"
      }
    ]
    
    # Auto-scaling configuration
    auto_scale = true
    min_nodes  = 2
    max_nodes  = 20
    
    # Custom tags for resource management
    tags = ["web-tier", "auto-scale", "production"]
  }
]
```

### Add-on Ecosystem
The module supports various add-ons through the `addons` configuration:

```hcl
addons = {
  # Ingress Controller
  ingress_nginx = {
    enabled = true
    version = "4.7.1"
    config = {
      replica_count = 2
      enable_ssl_passthrough = true
    }
  }
  
  # Certificate Management
  cert_manager = {
    enabled = true
    version = "v1.13.0"
    email   = "admin@company.com"
    config = {
      enable_http01_solver = true
      enable_dns01_solver  = false
    }
  }
  
  # GitOps
  argocd = {
    enabled = true
    version = "5.46.0"
    config = {
      enable_ha = true
      admin_password = "secure-password"
    }
  }
  
  # Service Mesh
  istio = {
    enabled = false
    version = "1.19.0"
    config = {
      enable_injection = true
    }
  }
}
```

## 📚 Examples

The module includes comprehensive examples in the `examples/` directory:

- **`examples/basic/`**: Simple single node pool cluster
- **`examples/production/`**: Production-ready multi-node pool setup
- **`examples/development/`**: Cost-optimized development environment
- **`examples/multi-region/`**: Multi-region deployment pattern
- **`examples/with-addons/`**: Cluster with common add-ons pre-installed

## 🐛 Troubleshooting

### Common Issues

#### Cluster Creation Failures
```bash
# Check DigitalOcean API limits
doctl account ratelimit

# Verify region availability
doctl kubernetes options regions

# Check Kubernetes version availability
doctl kubernetes options versions
```

#### Node Pool Issues
```bash
# Check node status
kubectl get nodes -o wide

# Describe problematic nodes
kubectl describe node <node-name>

# Check cluster autoscaler logs
kubectl logs -n kube-system deployment/cluster-autoscaler
```

#### Network Connectivity
```bash
# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Check service connectivity
kubectl get svc --all-namespaces

# Verify ingress configuration
kubectl get ingress --all-namespaces
```

### Debug Mode
Enable debug mode by setting:
```hcl
debug_mode = true
```

This enables:
- Detailed Terraform logging
- Extended Kubernetes API logging
- Debug annotations on resources

## 📝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details on:
- Code standards and style
- Testing requirements
- Pull request process
- Issue reporting

### Development Setup
```bash
# Clone the repository
git clone <repository-url>
cd terraform-digitalocean-k8s

# Install development dependencies
make install-deps

# Run tests
make test

# Run linting
make lint
```

## 📄 License

This module is licensed under the MIT License. See [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: [Full documentation](docs/)
- **Issues**: [GitHub Issues](issues/)
- **Discussions**: [GitHub Discussions](discussions/)
- **Community**: [Slack Channel](slack-invite-link)

## 🔗 Related Resources

- [DigitalOcean Kubernetes Documentation](https://docs.digitalocean.com/products/kubernetes/)
- [Terraform DigitalOcean Provider](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)

---

**Maintained with ❤️ by the Platform Engineering Team**