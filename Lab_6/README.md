#
# Lab 6 : 6 : Installation d'AGIC, déploiement d'Azure Application Gateway et déploiement d'une application basique
#
      
--------------------------------------------------------------------------------------------------------

## Objectifs
Utiliser Azure Application Gateway comme solution de reverse proxy pour exposer des applications exécutées dans Azure Kubernetes Service.

Plus d'informations sur Azure Application Gateway : https://docs.microsoft.com/en-us/azure/application-gateway/overview

Azure Application Gateway sera piloté par AGIC (Azure Application Gateway Ingress Controller)

Plus d'informations sur AGIC : https://docs.microsoft.com/en-us/azure/application-gateway/ingress-controller-overview

<img width='800' src='../images/architecture-AGIC.png'/>

Les règles de routage http(s) seront définies dans des objets Ingress dans Kubernetes.

Plus d'informations sur les objets Ingress : https://kubernetes.io/docs/concepts/services-networking/ingress/

[![](https://mermaid.ink/img/pako:eNqNkstuwyAQRX8F4U0r2VHqPlSRKqt0UamLqlnaWWAYJygYLB59KMm_Fxcix-qmGwbuXA7DwAEzzQETXKutof0Ovb4vaoUQkwKUu6pi3FwXM_QSHGBt0VFFt8DRU2OWSGrKUUMlVQwMmhVLEV1Vcm9-aUksiuXRaO_CEhkv4WjBfAgG1TrGaLa-iaUw6a0DcwGI-WgOsF7zm-pN881fvRx1UDzeiFq7ghb1kgqFWiElyTjnuXVG74FkbdumefEpuNuRu_4rZ1pqQ7L5fL6YQPaPNiFuywcG9_-ihNyUkm6YSONWkjVNM8WUIyaeOJLO3clTB_KhL8NQDmVe-OJjxgZM5FhFiiFTK5zjDkxHBQ9_4zB4a-x20EGNSZhyaKmXrg7f5hSsvufUwTMXThtMnPGQY-qdXn8rdl5Hz0rQ8LhdFE8_U8nfpA)](https://mermaid.live/edit#pako:eNqNkstuwyAQRX8F4U0r2VHqPlSRKqt0UamLqlnaWWAYJygYLB59KMm_Fxcix-qmGwbuXA7DwAEzzQETXKutof0Ovb4vaoUQkwKUu6pi3FwXM_QSHGBt0VFFt8DRU2OWSGrKUUMlVQwMmhVLEV1Vcm9-aUksiuXRaO_CEhkv4WjBfAgG1TrGaLa-iaUw6a0DcwGI-WgOsF7zm-pN881fvRx1UDzeiFq7ghb1kgqFWiElyTjnuXVG74FkbdumefEpuNuRu_4rZ1pqQ7L5fL6YQPaPNiFuywcG9_-ihNyUkm6YSONWkjVNM8WUIyaeOJLO3clTB_KhL8NQDmVe-OJjxgZM5FhFiiFTK5zjDkxHBQ9_4zB4a-x20EGNSZhyaKmXrg7f5hSsvufUwTMXThtMnPGQY-qdXn8rdl5Hz0rQ8LhdFE8_U8nfpA)

L'installation d'Azure Application Gateway et d'AGIC sera faite via l'utilisation d'un add-on à Azure Kubernetes Service

Azure Application Gateway peut être installé en mode GreenField lors de l'installation du cluster AKS si on active l'add on AGIC. Les ressources Azure associée seront alors dans le Resource Group où sont les VMScaleSet des node pools. Dans ce cas, le cycle de vie d'Azure Application Gateway sera celui du cluster AKS.

Une Azure Application Gateway existante peut être piloté par AGIC en activant le add-on sur un cluster AKS existant. 

Plus d'information : https://docs.microsoft.com/en-us/azure/application-gateway/tutorial-ingress-controller-add-on-existing

Dans ce lab, pour des raisons de simplicité, l'option _Greenfield_ est retenue.

---

## Pré-requis sur le poste d'administration
- Un abonnement Azure avec les privilèges d'administration (idéalement owner)
- Azure CLI 2.37 or >: [https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) 
- kubectl 

Les opérations sont réalisables depuis l'Azure Cloud Shell : https://shell.azure.com 

--- 

## Création d'un cluster AKS avec le add-on AGIC en mode greenfield

```bash
az login
az group create --name "RG-Lab6" --location "eastus2"
az aks create -n myCluster -g "RG-Lab6" --network-plugin azure --enable-managed-identity -a ingress-appgw --appgw-name myApplicationGateway --appgw-subnet-cidr "10.225.0.0/16" --generate-ssh-keys 
```

note : par défaut, la plage d'adresse IP d'un VNet créé pour AKS est désormais 10.224.0.0/12  (avant c'était 10.0.0.0/8)
cf. https://github.com/Azure/AKS/blob/master/CHANGELOG.md#release-notes-13
cf. https://jodies.de/ipcalc?host=10.224.0.0&mask1=12&mask2=
cf. https://stackoverflow.com/questions/72062611/aks-create-with-app-gateway-ingress-control-fails-with-ingressappgwaddonconfigin

---

## Vérification de l'installation de add-on AGIC sur le cluster AKS

Lister les clusters AKS disponibles 
```bash
az aks list -o table
```

Lister les add-ons installés sur un cluster AKS
```bash
az aks addon list -n <nomduclusterAKS> -g <nomduResourceGroupduControlPlane> -o table
```

Le résultat devrait être le suivant :
```bash
Name                             Enabled
-------------------------------  ---------
http_application_routing         False
monitoring                       False
virtual-node                     False
kube-dashboard                   False
azure-policy                     False
ingress-appgw                    True
confcom                          False
open-service-mesh                False
azure-keyvault-secrets-provider  False
gitops                           False
web_application_routing          False
```

Noter ingress-appgw qui est à true

---

## Déploiement d'une application et test de la solution de Ingress

Récupérer le kubeconfig permettant à kubectl de s'authentifier auprès de l'API Server du cluster AKS

```bash
az aks get-credentials -n "myCluster" -g "RG-Lab6"
```

Lister les classes d'ingress disponibles dans le cluster :

```bash
kubectl get ingressclasses.networking.k8s.io
```

Le résultat doit être : 

```bash
NAME                        CONTROLLER                  PARAMETERS   AGE
azure-application-gateway   azure/application-gateway   <none>       6m30s
```

Lister les objets ingress dans le cluster Kubernetes
```
kubectl get ingress --all-namespaces
```

Normalement il doit y avoir comme réponse **No resource found**

Dans le portail Azure, aller dans le resource group MC_.... contenant les ressources du cluster AKS 

Ouvrir la ressource Application Gateway

Sur le panneau de gauche, aller dans Rules et dans Backend pools et regarder les configurations par défaut (avec aucune)

Installer une application de démonstration

```bash
wget https://raw.githubusercontent.com/kubernetes/examples/master/guestbook/all-in-one/guestbook-all-in-one.yaml 
```

```bash
kubectl apply -f guestbook-all-in-one.yaml

kubectl get pods -n default -o wide
```

--> Dans le namespace default, il doit y avoir 3 frontend, 1 redis master et 2 redis replicas

Répéter la commande jusqu'à que les 6 pods soient en état running

```bash
kubectl get services -n default
```

Les services frontend, redis-master et redis-replica ne doivent pas avoir d'adresses IP externes

```bash
kubectl get ingress -n default
```

```
wget https://raw.githubusercontent.com/kubernetes/examples/master/guestbook/all-in-one/ing-guestbook.yaml
```

Visualiser le contenu du fichier ing-guestbook.yaml puis appliquer ce fichier

```bash
kubectl apply -f ing-guestbook.yaml

kubectl get services -n default -o wide

kubectl get ingress -n default
```

ouvrir un navigateur et se connecter sur l'url (qui est ici juste une adresse IP) ....

Dans le portail Azure, aller dans le resource group MC_.... contenant les ressources du cluster AKS 

Ouvrir la ressource Application Gateway et regarder les changements faits par AGIC sur la configuration : 

- Listener 
- Rules
- Backend pools : à comparer avec les résultats de la commande
```bash
kubectl get pod -n default -o wide
```
- Backend settings

## nettoyage
Supprimer le resource group RG-Lab6

```bash
az group delete -n RG-Lab6
```

Fin du Lab 6
