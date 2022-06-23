# Lab 2 : création d'un cluster plus avancé via Azure CLI, connexion et utilisation basique de kubectl
1. Prérequis:
- Checkez votre abonnement: `az account list -o table`
- Option: Pour se mettre dans son abonnement `az account set --subscription 'mon_abonnement'`
- Checkez les providers: Microsoft.OperationsManagement & Microsoft.OperationalInsights
`az provider show -n Microsoft.OperationsManagement -o table`
`az provider show -n Microsoft.OperationalInsights -o table`
- Option: Pour enregistrer les providers
`az provider register --namespace Microsoft.OperationsManagement`
`az provider register --namespace Microsoft.OperationalInsights`

2. Création d'un "resource group"<br>
`az group create --location westeurope --resource-group RG-AKS-CLI`