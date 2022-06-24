# Lab 2 : création d'un cluster plus avancé via Azure CLI, connexion et utilisation basique de kubectl
1. Prérequis:<br>
- Checkez votre abonnement:<br> `az account list -o table`
- Option: Pour se mettre dans son abonnement <br> `az account set --subscription 'mon_abonnement'`
- Checkez les providers: Microsoft.OperationsManagement & Microsoft.OperationalInsights<br>
`az provider show -n Microsoft.OperationsManagement -o table`<br>
`az provider show -n Microsoft.OperationalInsights -o table`<br>
- Option: Pour enregistrer les providers<br>
`az provider register --namespace Microsoft.OperationsManagement`<br>
`az provider register --namespace Microsoft.OperationalInsights`<br>

2. Création d'un "resource group"<br>
```
az group create \
    --location "westeurope" \
    --resource-group "RG-AKS-CLI"
```
3. Création d'une "Public Ip" <br>
```
az network public-ip create \
    --resource-group RG-AKS-CLI \
    --name natGatewaypIpAks \
    --location westeurope \
    --sku standard  
```
4. Création d'une "Azure nat Gateway" <br>
```
az network nat gateway create \
    --resource-group RG-AKS-CLI \
    --name natGatewayAks \
    --location westeurope \
    --public-ip-addresses natGatewaypIpAks

```
5. Création d'un "Virtual Network" <br>
```
az network vnet create \
    --resource-group RG-AKS-CLI \
    --name AKSvnet \
    --location westeurope \
    --address-prefixes 172.16.0.0/20
```
6. Création d'un "subnet avec le paramétrage de la nat Gateway" <br>
```
SUBNET_ID=$(az network vnet subnet create \
    --resource-group RG-AKS-CLI \
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
      --resource-group RG-AKS-CLI  \
      --workspace-name Workspace-AKS-CLI \
      --location westeurope \
      --query id \
      -o tsv
)
```
8. Création d'une "Azure Container Registry" <br>
```
az acr create \
  --name acrakscli00 \
  --resource-group RG-AKS-CLI \
  --sku basic
```
9. Création d'une "Managed Identity" <br>
```
IDENTITY_ID=$(az identity create \
    --resource-group RG-AKS-CLI \
    --name idAks \
    --location westeurope \
    --query id \
    --output tsv)
```
10. Création du "cluster AKS" <br>
```
az aks create \
    --resource-group RG-AKS-CLI \
    --name AKS-CLI \
    --location westeurope \
    --network-plugin azure \
    --generate-ssh-keys \
    --node-count 1 \
    --enable-cluster-autoscaler \
    --min-count 1 \
    --max-count 3 \
    --vnet-subnet-id $SUBNET_ID \
    --outbound-type userAssignedNATGateway \
    --enable-managed-identity \
    --assign-identity $IDENTITY_ID \
    --enable-addons monitoring \
    --workspace-resource-id ${AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID} \
    --attach-acr acrakscli00
```
11. Test du Cluster AKS <br>
- Connexion au cluster
`az aks get-credentials --resource-group RG-AKS-CLI --name AKS-CLI `




