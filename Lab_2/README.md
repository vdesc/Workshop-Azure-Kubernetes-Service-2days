# Lab 2 : création d'un cluster plus avancé via Azure CLI, connexion et utilisation basique de kubectl
1. Cloud Shell et prérequis
Allez: https://shell.azure.com
Prende le "Bash"
Checkez votre abonnement:`az account show -o table`
Option: Pour se mettre dans son abonnement`az account set --subscription 'mon_abonnement'`
Checkez les providers: Microsoft.OperationsManagement & Microsoft.OperationalInsights
`az provider show -n Microsoft.OperationsManagement -o table`
`az provider show -n Microsoft.OperationalInsights -o table`
Option: Pour enregistrer les providers
`az provider register --namespace Microsoft.OperationsManagement`
`az provider register --namespace Microsoft.OperationalInsights`

