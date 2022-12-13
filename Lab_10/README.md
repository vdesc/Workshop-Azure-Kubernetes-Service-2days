## Lab 10 : Pipeline CI/CD
## Objectif:
1. **Création de l'environnement de démonstration** <br>
**_Déploiement du "resource group":_**
```
az group create \
    --location "eastus2" \
    --resource-group "RG-AKS-Lab-10"
```
**_Déploiement d'un virtual network:_**
```
az network vnet create \
    --resource-group "RG-AKS-Lab-10" \
    --name AKSvnet \
    --location "eastus2" \
    --address-prefixes 10.0.0.0/8
```
**_Déploiement du subnet_:**
```
SUBNET_ID=$(az network vnet subnet create \
    --resource-group "RG-AKS-Lab-10" \
    --vnet-name AKSvnet \
    --name subnetAKS \
    --address-prefixes 10.240.0.0/16 \
    --query id \
    --output tsv)
```
**_Création d'une "Managed Identity":_**
```
IDENTITY_ID=$(az identity create \
    --resource-group "RG-AKS-Lab-10" \
    --name idAks \
    --location "eastus2" \
    --query id \
    --output tsv)
```
**_Création d'une "Azure Container Registry"_**
```
az acr create \
  --name "acrlab0010" \
  --resource-group "RG-AKS-Lab-10" \
  --sku basic
```
**_Création du cluster AKS_**
```
az aks create \
    --resource-group "RG-AKS-Lab-10" \
    --name "AKS-Lab-10" \
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
    --attach-acr "acrlab0010" \
    --yes
```    
**_Connexion au cluster AKS_**

`az aks get-credentials --resource-group RG-AKS-Lab-10 --name AKS-Lab-10`

**_Prérequis:_**<br>
`az ad sp create-for-rbac --name "votrenom-demo-githubaction2022" --role "Contributor" --scopes /subscriptions/METTRE_ICI_L_ID_DE_LA_SUBSCRIPTION --sdk-auth -o jsonc`<br>
```
{
  "clientId": "xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```
Copiez la sortie dans un notepad <br>
Créez un secret `CLIENTID` dans le service secret de GitHub<br>
Créez un secret `CLIENTSECRET` dans le service secret de GitHub<br>
Créez un secret `AZURE_CREDENTIALS` dans le service secret de GitHub<br><br>

**_Exécutions des "Workflows"_**<br>
Regardez, modifiez puis exécutez les deux workflows:<br>
`./github/workflows/Build.yaml`<br>
`./github/workflows/deploy.yaml`
  
