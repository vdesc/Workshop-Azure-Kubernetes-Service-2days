# Lab 5 : Azure Container Registry : configuration, importation et utilisation avec AKS
## Objectif:<br>
Quand vous utilisez Azure Container Registry (ACR) avec Azure Kubernetes Service (AKS), vous avez besoin d’un mécanisme d’authentification. L'oblectif de ce lab, c'est d'implémentée via l’interface Az CLI  les autorisations requises à votre Azure Container Registry.<br>

1. **Création de l'environnement de démonstration** <br>
**_Déploiement du "resource group":_**
```
az group create \
    --location "eastus2" \
    --resource-group "RG-AKS-Lab-5"
```
**_Déploiement d'un virtual network:_**
```
az network vnet create \
    --resource-group "RG-AKS-Lab-5" \
    --name AKSvnet \
    --location "eastus2" \
    --address-prefixes 10.0.0.0/8
```
**_Déploiement du subnet_:**
```
SUBNET_ID=$(az network vnet subnet create \
    --resource-group "RG-AKS-Lab-5" \
    --vnet-name AKSvnet \
    --name subnetAKS \
    --address-prefixes 10.240.0.0/16 \
    --query id \
    --output tsv)
```
**_Création d'une "Managed Identity":_**
```
IDENTITY_ID=$(az identity create \
    --resource-group "RG-AKS-Lab-5" \
    --name idAks \
    --location "eastus2" \
    --query id \
    --output tsv)
```
**_Création du "cluster AKS":_**
```
az aks create \
    --resource-group "RG-AKS-Lab-5" \
    --name "AKS-Lab-5" \
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
Danc ce scénario on intègre une Azure Container Registry avec un cluster AKS déjà déployé. Cela aurait pu être fait lors de la création du cluster<br>
**_Création de l'"Azure Container Registry":_**
```
az acr create \
  --name "acrakslab5" \
  --resource-group "RG-AKS-Lab-5" \
  --sku basic
```
**_Intégration du cluster AKS à l'"Azure Container Registry":_**
```
az aks update \
   --name "AKS-Lab-5" \
   --resource-group "RG-AKS-Lab-5" \
   --attach-acr "acrakslab5"
```
