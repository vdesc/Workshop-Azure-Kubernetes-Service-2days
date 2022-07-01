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
