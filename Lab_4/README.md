# Lab 4 : Activation du monitoring avec Azure Monitor
## Objectif:
Savoir utiliser Azure Monitor pour surveiller l’intégrité et les performances d’Azure Kubernetes Service (AKS). Cela comprend :<br>
- la collecte des données de télémétrie critiques pour la surveillance <br>
- l’analyse et la visualisation des données collectées pour identifier les tendances <br>
- configurer des alertes pour être informé de manière proactive des problèmes critiques <br>

1. Création de l'environnement de démonstration <br>
- Déploiement du "resource group"<br>
```
az group create \
    --location "eastus2" \
    --resource-group "RG-AKS-Lab-4"

```
- Déploiement d'un virtual network
```
az network vnet create \
    --resource-group "RG-AKS-Lab-4" \
    --name AKSvnet \
    --location "eastus2" \
    --address-prefixes 10.0.0.0/8
```
- Déploiement du subnet
```
SUBNET_ID=$(az network vnet subnet create \
    --resource-group "RG-AKS-Lab-4" \
    --vnet-name AKSvnet \
    --name subnetAKS \
    --address-prefixes 10.240.0.0/16 \
    --query id \
    --output tsv)
```
- Création d'une "Managed Identity" <br>
```
IDENTITY_ID=$(az identity create \
    --resource-group "RG-AKS-Lab-4" \
    --name idAks \
    --location "eastus2" \
    --query id \
    --output tsv)
```
- Création du "cluster AKS" <br>
```
az aks create \
    --resource-group "RG-AKS-Lab-4" \
    --name "AKS-Lab-4" \
    --location "eastus2" \
    --network-plugin azure \
    --generate-ssh-keys \
    --node-count 2 \
    --enable-cluster-autoscaler \
    --min-count 1 \
    --max-count 3 \
    --vnet-subnet-id $SUBNET_ID \
    --enable-managed-identity \
    --assign-identity $IDENTITY_ID \
    --yes

```
2. Activation du monitoring
- Création d'un "Workspace Logs analytic <br>
```
AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID=$(
   az monitor log-analytics workspace create \
      --resource-group "RG-AKS-CLI"  \
      --workspace-name "Workspace-AKS-Lab-4" \
      --location "eastus2" \
      --query id \
      -o tsv
)
```
