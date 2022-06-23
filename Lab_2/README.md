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

2. Création d'un "resource group"
`az group create --location westeurope --resource-group RG-AKS-CLI`