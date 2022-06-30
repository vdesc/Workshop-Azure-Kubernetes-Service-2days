# Lab 2 : création d'un cluster plus avancé via Azure CLI, connexion et utilisation basique de kubectl
## Objectif:
L'objectif de ce Lab 2, c'est de déployer un cluster AKS en Az CLI avec une configuration de type de "NAT Gateway", c'est à dire, d'avoir le contrôle de l'IP publique sortantes des "Node Pool".<br>
Remarque: Il n'est pas possible de le faire dans la console. 


1. Prérequis:<br>
- Checkez votre abonnement:<br> `az account list -o table`
- Option: Pour se mettre dans son abonnement <br> `az account set --subscription 'mon_abonnement'`
- Checkez les providers: Microsoft.OperationsManagement & Microsoft.OperationalInsights<br>
`az provider show -n Microsoft.OperationsManagement -o table`<br>
`az provider show -n Microsoft.OperationalInsights -o table`<br>
- Option: Pour enregistrer les providers<br>
`az provider register --namespace Microsoft.OperationsManagement`<br>
`az provider register --namespace Microsoft.OperationalInsights`<br>
- Pour faire ce Lab, mettre ses propres paramètres dans les "double cote" (ex: "RG-AKS-CLI" -> "mon-resource-group") <br>
- Vous pouvez lancer les commandes une par une ou faite un script <br>

2. Création d'un "resource group"<br>
```
az group create \
    --location "eastus2" \
    --resource-group "RG-AKS-CLI"
```
3. Création d'une "Public Ip" <br>
```
az network public-ip create \
    --resource-group "RG-AKS-CLI" \
    --name natGatewaypIpAks \
    --location "eastus2" \
    --sku standard  
```
4. Création d'une "Azure nat Gateway" <br>
```
az network nat gateway create \
    --resource-group "RG-AKS-CLI" \
    --name natGatewayAks \
    --location "eastus2" \
    --public-ip-addresses natGatewaypIpAks
```
5. Création d'un "Virtual Network" <br>
```
az network vnet create \
    --resource-group "RG-AKS-CLI" \
    --name AKSvnet \
    --location "eastus2" \
    --address-prefixes 172.16.0.0/20
```
6. Création d'un "subnet avec le paramétrage de la nat Gateway" <br>
```
SUBNET_ID=$(az network vnet subnet create \
    --resource-group "RG-AKS-CLI" \
    --vnet-name AKSvnet \
    --name natclusterAKS \
    --address-prefixes 172.16.0.0/22 \
    --nat-gateway natGatewayAks \
    --query id \
    --output tsv)
```
7. Création d'un "Workspace Logs Analytics" <br>
```
AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID=$(
   az monitor log-analytics workspace create \
      --resource-group "RG-AKS-CLI"  \
      --workspace-name Workspace-AKS-CLI \
      --location "eastus2" \
      --query id \
      -o tsv
)
```
8. Création d'une "Azure Container Registry" <br>
```
az acr create \
  --name "acrakscli00" \
  --resource-group "RG-AKS-CLI" \
  --sku basic
```
9. Création d'une "Managed Identity" <br>
```
IDENTITY_ID=$(az identity create \
    --resource-group "RG-AKS-CLI" \
    --name idAks \
    --location "eastus2" \
    --query id \
    --output tsv)
```
10. Création du "cluster AKS" <br>
```
az aks create \
    --resource-group "RG-AKS-CLI" \
    --name "AKS-CLI" \
    --location "eastus2" \
    --network-plugin azure \
    --generate-ssh-keys \
    --node-count 2 \
    --enable-cluster-autoscaler \
    --min-count 1 \
    --max-count 3 \
    --vnet-subnet-id $SUBNET_ID \
    --outbound-type userAssignedNATGateway \
    --enable-managed-identity \
    --assign-identity $IDENTITY_ID \
    --enable-addons monitoring \
    --workspace-resource-id ${AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID} \
    --attach-acr "acrakscli00"
```
11. Test du Cluster AKS <br>
- Connexion au cluster <br>
`az aks get-credentials --resource-group "RG-AKS-CLI" --name "AKS-CLI" ` <br>
- Liste des nodes du cluster <br>
`kubectl get nodes` <br>
12. Importation d'image dans votre Azure Container Registry <br>
- Connexion à l' Azure Container Registry <br>
`az acr login --name "acrakscli00" --expose-token`
- Importation d'images <br>
```
az acr import \
  --name "acrakscli00" \
  --source mcr.microsoft.com/oss/bitnami/redis:6.0.8 \
  --image redis:6.0.8
```
```
az acr import \
  --name "acrakscli00" \
  --source mcr.microsoft.com/azuredocs/azure-vote-front:v1 \
  --image azure-vote-front:v1
```
13. Création du fichier Manifest <br>
- créez un fichier config.yml (ex : `touch config.yml`) <br>
- Dans le repo, allez dans le fichier ./Manifest/config.yml <br>
- remplacer (vi, nano, ...)  <br>
mcr.microsoft.com/oss/bitnami/redis:6.0.8 -> acrakscli00.azurecr.io/redis:6.0.8 <br>
mcr.microsoft.com/azuredocs/azure-vote-front:v1 -> acrakscli00.azurecr.io/azure-vote-front:v1 <br>





