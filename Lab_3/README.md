#
# Lab 3 : déploiement et gestion de la configuration d'Azure Kubernetes Service avec Terraform
#
      
=== version up to date June 2022 ===

= Tested with success with Terraform v1.2.2 on linux_amd64 (WSL2)
+ provider registry.terraform.io/hashicorp/azurerm v3.10.0
+ provider registry.terraform.io/hashicorp/helm v2.5.0
+ provider registry.terraform.io/hashicorp/kubernetes v2.10.0
+ provider registry.terraform.io/hashicorp/random v3.3.1
+ provider registry.terraform.io/providers/hashicorp/time v0.7.2

--------------------------------------------------------------------------------------------------------

## Objectifs

Ceci est un ensemble de fichiers Terraform pour déployer un cluster Azure Kubernetes Cluster avec les options suivantes: 

- Les Nodes sont dispatchés dans plusieurs Availability Zones (AZ)
- Les Node pools sont configurés en mode autoscaling
- pool1 est le node pool system sous Linux  a linux (exécute les pods dans le namespace kube system pods)
- pool2 (optionnel) est un node pool Windows Server 2022 avec une "taint"
- les node pool ont des Managed Identities 
- Choix possible de la SKU du Control Plane (Free or Paid)
- Les add-ons suivants : Azure Monitor

Les ressources déployées par ce code Terraform sont les suivantes :

- Un Azure Resource Group
- Un cluster Azure Kubernetes Services Cluster with 1 node pool (1 Virtual Machine ScaleSet) linux
- Un node pool Windows Server 2019 (1 Virtual Machine ScaleSet)
- Deux Managed Identities (une par VMSS)
- Un Azure Load Balancer Standard SKU
- Une Azure Public IP
- Un Virtual Network avec ses Subnets (subnet pour les pods AKS, de subnets pour AzureBastion,Azure Firewall, Azure Application Gateway
- Un Azure Log Analytics Workspace (used for Azure Monitor Container Insight)
- Azure Application Gateway + Application Gateway Ingress Controller AKS add-on
- An Azure Log Analytics Workspace (used for Azure Monitor Container Insight)

On Kubernetes, these Terraform files will :

- Deploy Grafana using Bitnami Helm Chart and exposed Grafana Dashboard using Ingress (and AGIC)
- Create a pod, a service and an ingress (the file associated is renamed in .old because of issue during first terraform plan) 

## Pré-requis sur le poste d'administration

- An Azure Subscription with enough privileges (create RG, AKS...)
- Azure CLI 2.37 or >: <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest>
   And you need to activate features that are still in preview and add extension aks-preview to azure CLI (az extension add --name aks-preview)
- Terraform CLI 1.2.2 or > : <https://www.terraform.io/downloads.html>
- Helm CLI 3.9.0 or > : <https://helm.sh/docs/intro/install/> if you need to test Helm charts


## Préparation de l'environnement AVANT le déploiement avec Terraform

- Ouvrir une session Bash et se connecter à votre abonnement Azure

```bash
az login
```

- Création d'un resource group RG-AdminZone

```bash
az group create --name "RG-AdminZone" --location "eastus2"
```

- Création d'un compte de Stockage Azure dans RG-AdminZone

```bash
az storage account create \
  --name "<your-unique-storageaccount-name>" \
  --resource-group "RG-AdminZone" \
  --location "eastus2" \
  --sku "Standard_LRS" \
  --kind "StorageV2"
```

- Création d'un container TFState dans la partie Blobs du compte de stockage. Ce container contiendra le(s) Remote TFState(s) des déploiements Terraform

cf. https://docs.microsoft.com/en-us/cli/azure/storage/container?view=azure-cli-latest

cf. https://www.terraform.io/language/settings/backends/azurerm

```bash
az storage container create --name "tfstate" --account-name "<your-unique-storageaccount-name>" --resource-group "RG-AdminZone" --public-access "off"
```

- Création d'un token SAS pour le container tfstate du compte de stockage
cf. https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blob-user-delegation-sas-create-cli#create-a-user-delegation-sas-for-a-container
cf. https://docs.microsoft.com/en-us/cli/azure/storage/container?view=azure-cli-latest#az-storage-container-generate-sas

```bash
az storage container generate-sas \
    --account-name "<your-unique-storageaccount-name>" \
    --name "tfstate" \
    --permissions acdlrw \
    --start "2022-06-13" \
    --expiry "2022-06-19"  \
    --auth-mode key
```

- Création d'un Azure Key Vault dans RG_AdminZone

cf. https://docs.microsoft.com/en-us/cli/azure/keyvault?view=azure-cli-latest#az-keyvault-create

```bash
az keyvault create --name "<your-unique-keyvault-name>" --resource-group "RG-AdminZone" --location "eastus2"
```

- Création d'un secret __"MySecret"__ dans Azure Key Vault

cf. https://docs.microsoft.com/en-us/cli/azure/keyvault/secret?view=azure-cli-latest#az-keyvault-secret-set 

```bash
az keyvault secret set --name "MySecret" --vault-name "<your-unique-keyvault-name>" --value "<laveurdemonsecret>"
```

Création d'un secret __"ClePubliqueSSH"__ dans Azure Key Vault Mettre votre clé SSH publique (contenu de .ssh/id_rsa.pub)

```bash
az keyvault secret set --name "ClePubliqueSSH" --vault-name "<your-unique-keyvault-name>" --value "<laveurdevotrecleSSHpublique>"
```

## Déploiement du Cluster AKS

1. Ouvrir une session Bash et se connecter à votre abonnement Azure

```bash
az login
```

2. Editer le fichier __configuration.tfvars__ et compléter avec vos valeurs

3. Editer le fichier __1-versions.tf__ et modifier les paramètres relatifs au Remote Backend terraform

4- Visualiser et modifier si besoin le fichier __"3-vars.tf"__

5. Initialiser le déploiement terraform

```bash
terraform init
```

6. Planifier le déploiement terraform

```bash
terraform plan --var-file=myconfiguration.tfvars
```

6. Apply your terraform deployment

```bash
terraform apply --var-file=myconfiguration.tfvars
```


## Vérification du déploiement du cluster

After deployment is succeeded, you can check your cluster using portal or better with azure cli and the following command: 

Une fois le déploiement effectué, vérifier le cluster en utilisant le portail Azure ou mieux avec Azure CLI

```bash
az aks show --resource-group "<your-AKS-resource-group-name>" --name "<your-AKS-cluster-name>" -o jsonc
```

Get your kubeconfig using :

```bash
az aks get-credentials --resource-group "<your-AKS-resource-group-name>" --name "<your-AKS-cluster-name>" --admin
```

