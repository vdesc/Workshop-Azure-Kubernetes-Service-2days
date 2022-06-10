# Lab 2 : création d'un cluster plus avancé via Azure CLI, connexion et utilisation basique de kubectl
1. Cloud Shell et prérequis<br>
Allez: https://shell.azure.com<br>
Prende le "Bash"<br>
Checkez votre abonnement: `az account show -o table`<br>
Option: Pour se mettre dans son abonnement `az account set --subscription 'mon_abonnement'`<br>
Checkez les providers: Microsoft.OperationsManagement & Microsoft.OperationalInsights<br>
`az provider show -n Microsoft.OperationsManagement -o table`<br>
`az provider show -n Microsoft.OperationalInsights -o table`<br>
Option: Pour enregistrer les providers<br>
`az provider register --namespace Microsoft.OperationsManagement`<br>
`az provider register --namespace Microsoft.OperationalInsights`<br>

2. Création d'un "resource group"<br>
`az group create --location westeurope --resource-group RG-AKS-CLI`
3. Création du cluster AKS<br>
Voir les commandes:  `az aks --help` & `az aks create --help`<br>
Création d'un simple cluster <br>
`az aks create --resource-group RG-AKS-CLI --name AKS-CLI --node-count 1 --enable-addons monitoring --generate-ssh-keys`