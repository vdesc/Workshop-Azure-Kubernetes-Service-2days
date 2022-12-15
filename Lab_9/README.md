## Montées de version de l'application: Rolling update, Blue Green, Canary
# Objectif:
Comprendre les concepts de montées de version des applications dans un cluster Kubernetes.

L'objectif de ce Lab 9 est aussi de voir comment répartir le trafic réseau entre plusieurs versions d'une application.

Les patterns les plus classiques en termes de répartition de trafic entre plusieurs versions d'une application étant :
- le Rolling Update
        - https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
- le vert/bleu (ou noir/rouge chez Netflix)
	- https://martinfowler.com/bliki/BlueGreenDeployment.html
- le A/B testing
	- https://en.wikipedia.org/wiki/A/B_testing
- le canary
    - https://blog.itaysk.com/2017/11/20/deployment-strategies-defined#:~:text=It%E2%80%99s%20described%20next.-,Canary%20Deployment,-a.k.a

# **Création de l'environnement de démonstration** <br>
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
```
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
```

**_Connexion au cluster AKS_**

```
az aks get-credentials --resource-group RG-AKS-Lab-9 --name AKS-Lab-9
```  

# **Build and Push les deux versions d'application** <br>
API v1: <br>
-> Allez dans ./API/v1 et lancer cette commande <br>
```
az acr build -t api/api:1.0.0 -r "acrlab009" .
```

API v2: <br>
-> Allez dans ./API/v2 et lancer cette commande<br>
```
az acr build -t api/api:2.0.0 -r "acrlab009" .
```
Tests des pushs:<br>
```
az acr repository show --name acrlab009 --image api/api:1.0.0
```

# **Déploiement de l'application**
Installation de l'application:<br>
Allez dans ./Manifest<br>
```
kubectl apply -f ./v1
```

Check:
```
watch kubectl get all --namespace namespacelab9
```
ctl+c pour sortir <br>
Pour visionner la version déployée <br>
```
kubectl rollout history deployment api-deployment --namespace namespacelab9
```
Pour mettre une annotation à la version (revision)<br>
```
kubectl annotate deployments.apps api-deployment kubernetes.io/change-cause="version blue" --namespace namespacelab9
```
```
kubectl rollout history deployment api-deployment --namespace namespacelab9
```
```
kubectl get all --namespace namespacelab9

```

Executer la commande:<br>

```
curl http://<EXTERNAL-IP>
```

# **Mise à jour de l'application** <br><br>
**_Mise à jour de l'application en "rolling updates" avec des stratégies_**<br>
Allez dans le répertoire ./Manifest/v2/rollingupdate et observer le fichier update.yaml ( au niveau "spec et strategy").
```
cd ..
kubectl apply -f ./rollingupdate/update.yaml
```
Visionner la mise à jour de la version 2<br>
```
watch kubectl get all --namespace namespacelab9
```
attendre qu'il n'y est plus que trois pods<br>
même procéder que pour la verion 1<br>
```
kubectl rollout history deployment api-deployment --namespace namespacelab9
kubectl annotate deployments.apps api-deployment kubernetes.io/change-cause="version green" --namespace namespacelab9
kubectl rollout history deployment api-deployment --namespace namespacelab9
```
test<br>
```
curl http://<EXTERNAL-IP>
```
Pour revenir à la version 1<br>
```
kubectl rollout undo deployment.apps/api-deployment --to-revision=1 --namespace namespacelab9
```
test<br>
```
curl http://<EXTERNAL-IP>
```

**_Mise à jour de l'application avec la méthode "blue green"_**<br>
On va repartir sur deux déploiements <br>
On détruit la configuration 
```
kubectl delete namespace namespacelab9
```

Premier déploiement:
Dans le répertoire ./Manifest/v2/bluegreen: 
```
kubectl apply -f ./namespace.yaml
kubectl apply -f ./deploymentv1.yaml
kubectl apply -f ./service.yaml
```

Test:<br>
```
kubectl get all --namespace namespacelab9
```

```
curl EXTERNAL-IP
```

```
{"message":"hello API Bleue"}
```
Deuxième déploiement:
```
kubectl apply -f ./deploymentv2.yaml
```

Redirection des flux vers la nouvelle version<br>
Editer le fichier `service.yaml`et modifier le "selector" et passez "app: API-v2"<br>
Appliquer la configuration:<br>
```
kubectl apply -f ./service.yaml
```
Check:<br>
```
curl EXTERNAL-IP
```

```
{"message":"hello API Green"}
```
Pour repasser à la version précédente remodifier le fichier `service.yaml` et modifier le "selector" et passer "app: API-v1"<br>

**_Mise à jour de l'application avec la méthode "canary"_**<br>
On va repartir sur deux déploiements <br>
On détruit la configuration 
```
kubectl delete namespace namespacelab9
```


Premier déploiement avec 3 réplicas:<br>
Dans le répertoire ./Manifest/v2/canary: 

```
kubectl apply -f ./namespace.yaml
kubectl apply -f ./deploymentv1.yaml
kubectl apply -f ./service.yaml
```

Test:
```
kubectl get all --namespace namespacelab9
```

```
curl EXTERNAL-IP
```

```
{"message":"hello API Bleue"}
```
Deuxième déploiement avec 1 réplica: (75-25)
```
kubectl apply -f ./deploymentv2.yaml
```

Test:
```
kubectl get all --namespace namespacelab9
```

Répéter la commande `curl EXTERNAL-IP` <br>
Vous devez avoir une fois sur quatre:<br>
```
{"message":"hello API Green"}
```
# **Nettoyage du Lab_9**
```
az group delete --name "RG-AKS-Lab-9"
```
