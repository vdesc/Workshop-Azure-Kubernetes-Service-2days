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
API v1: <br>
-> Allez dans ./API/v1 et lancer cette commande<br>
```
az acr build -t api/api:1.0.0 -r "acrlab009" .
```
API v2: <br>
-> Allez dans ./API/v2 et lancer cette commande<br>
```
az acr build -t api/api:2.0.0 -r "acrlab009" .
```
Tests des pushs:<br>
`az acr repository show --name acrlab009 --image api/api:1.0.0`<br>


3. **Deploiement de l'application**
Installation de l'application:<br>
Allez dans ./Manifest<br>
`kubectl apply -f ./v1`

Check:<br>
`kubectl get all --namespace namespacelab9`<br>
`curl http://<EXTERNAL-IP>`<br>

4. **Mise à jour de l'application** <br><br>
**_Laisser Kube gérer lui même ma monté de version de l'application_**<br>
Allez dans le répertoire ./Manifest/v2 
`kubectl apply -f ./kubefree`<br>
Répéter la commande `kubectl get all --namespace namespacelab9` pour voir l'évolution de la mise à jour de apllication <br>
Test: `curl http://EXTERNAL-IP`

**_Mise à jour de l'application en "rolling updates" avec des stratégies_**<br>
Pour cet exemple,on va reppaser dans la version précédente en "rolling update" avec des strategies<br>
Allez dans le répertoire ./Manifest/v2/rollingupdate et observer le fichier update.yaml ( au niveau "spec et strategy")<br>
`kubectl apply -f ./rollingupdate/update.yaml`<br>

**_Mise à jour de l'application avec la méthode "blue green"_**<br>
On va repartir sur deux déploiements <br>
On détruit la configuration `kubectl delete namespace namespacelab9`<br><br>
Premier déploiement:<br>
Dans le repertoire ./Manifest/v2/bluegreen: <br>
`kubectl apply -f ./namespace.yaml`<br>
`kubectl apply -f ./deploymentv1.yaml`<br>
`kubectl apply -f ./service.yaml`<br>
Test:<br>
`kubectl get all --namespace namespacelab9`<br>
`curl EXTERNAL-IP`
```
{"message":"hello API Bleue"}
```
Deuxième déploiement:<br>
`kubectl apply -f ./deploymentv2.yaml`<br>
Redirection des flux vers la nouvelle version<br>
Editez le fichier `service.yaml`et modifier le "selector" et passez "app: API-v2"<br>
Appliquez la configuration:<br>
`kubectl apply -f ./service.yaml`<br>
Check:<br>
`curl EXTERNAL-IP`<br>
```
{"message":"hello API Green"}
```




















