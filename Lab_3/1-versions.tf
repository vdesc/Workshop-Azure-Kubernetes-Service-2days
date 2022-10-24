#   _______                   __                                           _                                              _     _               
#  |__   __|                 / _|                                         (_)               ___                          (_)   | |              
#     | | ___ _ __ _ __ __ _| |_ ___  _ __ _ __ ___    __   _____ _ __ ___ _  ___  _ __    ( _ )     _ __  _ __ _____   ___  __| | ___ _ __ ___ 
#     | |/ _ \ '__| '__/ _` |  _/ _ \| '__| '_ ` _ \   \ \ / / _ \ '__/ __| |/ _ \| '_ \   / _ \/\  | '_ \| '__/ _ \ \ / / |/ _` |/ _ \ '__/ __|
#     | |  __/ |  | | | (_| | || (_) | |  | | | | | |   \ V /  __/ |  \__ \ | (_) | | | | | (_>  <  | |_) | | | (_) \ V /| | (_| |  __/ |  \__ \
#     |_|\___|_|  |_|  \__,_|_| \___/|_|  |_| |_| |_|    \_/ \___|_|  |___/_|\___/|_| |_|  \___/\/  | .__/|_|  \___/ \_/ |_|\__,_|\___|_|  |___/
#                                                                                                   | |                                         
#                                                                                                   |_|                                         

terraform {
  required_version = ">= 1.3.2"
  backend "azurerm" {
    resource_group_name  = "RG-AdminZone" # mettre ici le nom du resource group de vos ressource
    storage_account_name = "labmons" # /!\ mettre le nom du compte de stockage créer dans le lab 1
    container_name       = "tfstate"
    key                  = "aks.terraform.tfstate"
  }
  required_providers {
    azurerm = {
      # The "hashicorp" namespace is the new home for the HashiCorp-maintained
      # provider plugins.
      #
      # source is not required for the hashicorp/* namespace as a measure of
      # backward compatibility for commonly-used providers, but recommended for
      # explicitness.
      # Configure the Azure Provider
      # more info : https://github.com/terraform-providers/terraform-provider-azurerm
      # Check Changelog : https://github.com/terraform-providers/terraform-provider-azurerm/blob/master/CHANGELOG.md
      source  = "hashicorp/azurerm"
      version = ">= 3.1.0"
    }

    # https://github.com/hashicorp/terraform-provider-kubernetes
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "= 2.10.0"
    }

    # https://github.com/hashicorp/terraform-provider-helm
    helm = {
      source  = "hashicorp/helm"
      version = "2.5.0"
    }

    # https://github.com/hashicorp/terraform-provider-time
    time = {
      source  = "hashicorp/time"
      version = "0.7.2"
    }

    # grafana = {
    #   source  = "grafana/grafana"
    #   version = "1.22.0"
    # }
  }
}

# Configure the Azure Provider
provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  # More information on the `features` block https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#features
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Configure the Kubernetes Provider
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.Terra_aks.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.Terra_aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.Terra_aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.Terra_aks.kube_config.0.cluster_ca_certificate)
  # cf. https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/guides/alpha-manifest-migration-guide
  experiments {
    manifest_resource = true
  }
}

# Helm provider
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.Terra_aks.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.Terra_aks.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.Terra_aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.Terra_aks.kube_config.0.cluster_ca_certificate)
  }
}

# Time provider
provider "time" {
  # Configuration options
}

# Configuration provider Grafana
# cf. https://registry.terraform.io/providers/grafana/grafana/latest/docs
# provider "grafana" {
#   # url  = "http://grafana.example.com/"
#   url  = "http://${var.a-record-dns-ingress}.${var.dns-zone-name-for-ingress}"
#   auth = "${var.grafana_admin_username}:${data.azurerm_key_vault_secret.grafana_admin_password.value}"
# }


# A remote backend must be used for production (especially if deployments are done through CI/CD pipelines) 
# or if you are not working only with yourself as a lone ranger :)


###################################################################################
# Option 1 for Terraform Remote Backend : use Terraform Cloud Remote State Management
# https://www.hashicorp.com/blog/introducing-terraform-cloud-remote-state-management
# create your account here : https://app.terraform.io/session
####################################################################################
# Using a single workspace in Terraform Cloud Remote State / Terraform Enterprise
# terraform {
#   backend "remote" {
#     hostname = "app.terraform.io"
#     organization = "Insert here your organization name"
#     token = "Insert here your Token"
#     workspaces {
#       name = "deploiementVM-AKS"
#     }
#   }
# }


###################################################################################
# Option 2 for Terraform Remote Backend : use an Azure Storage Account
# ref : https://www.terraform.io/docs/backends/types/azurerm.html
####################################################################################
# You need as a prerequisite :
# A storage Account with a blob container into your deployment region
# Enable Secure Transfert Required option to force TLS usage
# create a blob container named terraform-state

# data "terraform_remote_state" "Terra-Backend-Stan1" {
#    backend = "azure"
#    config {
#        storage_account_name = "mettre ici le nom du compte de stockage"
#        container_name = "terraform-state"
#        key = "prod.terraform.tfstate"
#    }
# }
