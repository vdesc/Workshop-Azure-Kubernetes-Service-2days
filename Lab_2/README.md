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
    --location westeurope \
    --resource-group RG-AKS-CLI
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


