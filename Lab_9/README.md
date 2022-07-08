## Montées de version de l'application: Rolling update, Blue Green, Canary
# Obectif:
1. **Création de l'environnement de démonstration** <br>
**_Déploiement du "resource group":_**
```
az group create \
    --location "eastus2" \
    --resource-group "RG-AKS-Lab-9"
```
**_Déploiement d'un virtual network:_**
```
az network vnet create \
    --resource-group "RG-AKS-Lab-9" \
    --name AKSvnet \
    --location "eastus2" \
    --address-prefixes 10.0.0.0/8
```
**_Déploiement du subnet_:**
```
SUBNET_ID=$(az network vnet subnet create \
    --resource-group "RG-AKS-Lab-9" \
    --vnet-name AKSvnet \
    --name subnetAKS \
    --address-prefixes 10.240.0.0/16 \
    --query id \
    --output tsv)
```
**_Création d'une "Managed Identity":_**
```
IDENTITY_ID=$(az identity create \
    --resource-group "RG-AKS-Lab-9" \
    --name idAks \
    --location "eastus2" \
    --query id \
    --output tsv)
```
**_Création d'une "Azure Container Registry"_**
```
az acr create \
  --name "acrlab009" \
  --resource-group "RG-AKS-Lab-9" \
  --sku basic
```
**_Création du cluster AKS_**
az aks create \
    --resource-group "RG-AKS-Lab-9" \
    --name "AKS-Lab-9" \
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
    --attach-acr "acrlab009" \
    --yes

**_Connexion au cluster AKS_**
`az aks get-credentials --resource-group RG-AKS-Lab-9 --name AKS-Lab-9`  

2. **Build and Push les deux versions d'application** <br>
API blue: <br>
Allez dans ./API_Blue et lancer cette commande<br>
```
az acr build -t api/api:1.0.0 -r "acrlab009" .
```
