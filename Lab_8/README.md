# Lab 8 - Montées de versions AKS
tags: #azure #kubernetes #update #upgrade #version #patch

## Objectifs
Voir les différents niveaux de mises à jour possible sur un cluster Azure Kubernetes Service

Lectures additionnelles :

- Supported Kubernetes versions in Azure : https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli
- AKS Kubernetes Release Calendar : https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli#aks-kubernetes-release-calendar

## Pré-requis sur le poste d'administration

-   Un abonnement Azure avec les privilèges d'administration (idéalement owner)
-   Azure CLI 2.37 or >: [https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) 
-   kubectl

Les opérations sont réalisables depuis l'Azure Cloud Shell : [https://shell.azure.com](https://shell.azure.com/)

## Création d'un cluster AKS pour le lab

```bash
az login

az group create --name "RG-Lab8" --location "eastus2"

az aks create -n "myCluster" -g "RG-Lab8" --network-plugin azure --location "eastus2"

az aks get-credentials -n "myCluster" -g "RG-Lab8"
```

## Mises à jour de sécurité des systèmes d'exploitation des worker nodes
Les mises à jour de sécurité du système d'exploitation des worker nodes sont installées automatiquement toutes les 24h. 

Si une mise à jour Linux nécessite un rédemarrage, alors il est de la responsabilité du client de redémarrer le processus de redémarrage.

Celui-ci est automatisable facilement via l'utilisation de Kured (Kubernetes Reboot Daemon) et est parfaitement documenté ici : https://docs.microsoft.com/en-us/azure/aks/node-updates-kured

Il est donc recommandé de configurer ses clusters AKS avec Kured.

## Mise à jour de l'image des worker nodes
Dans une approche Cattle, la mise à jour in-place des composants installés dans le système d'exploitation des workers n'a pas de sens. Dans AKS, les équipes Produit proposent très fréquemment de nouvelles images des OS et la mise à jour d'un node pool va consister à instancier des nouveaux agents et à supprimer les anciens.

Les annonces sur les nouvelles image d'OS sont disponibles dans le changelog d'AKS : https://github.com/Azure/AKS/blob/master/CHANGELOG.md

Pour avoir plus de détails sur le contenu et les versions des images OS :
	- images Ubuntu : https://github.com/Azure/AKS/tree/2022-07-03/vhd-notes/aks-ubuntu
	- images Windows : https://github.com/Azure/AKS/tree/2022-07-03/vhd-notes/AKSWindows

Pour visualiser la version de l'image en cours d'utilisation sur un nodepool 
```bash
az aks nodepool list --resource-group "RG-Lab8" --cluster-name "MyCluster" -o yaml | grep nodeImageVersion
```

La commande suivante donne un résultat similaire
```bash
az aks nodepool show \
    --resource-group "RG-Lab8" \
    --cluster-name "MyCluster" \
    --name "nodepool1" \
    --query nodeImageVersion
```

Pour mettre à jour un node pool avec la dernière version de l'image OS, cela est possible et orchestré via l'option __--node-image__ de la commande az aks upgrade 

```bash
az aks nodepool upgrade \
    --resource-group "RG-Lab8" \
    --cluster-name "MyCluster" \
    --name "MyCluster" \
    --node-image-only \
    --no-wait
```

Pendant la mise à jour (si une version plus récente de l'image est disponible), il est possible de surveiller les changements

```bash 
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels.kubernetes\.azure\.com\/node-image-version}{"\n"}{end}'
```

## Mise à jour de la version de Kubernetes

Vérifier les mises à jour de Kubernetes disponibles
```bash
az aks get-upgrades --resource-group "RG-Lab8" --name "myCluster" -o table
```

Il est possible de faire la vérification à l'échelle d'un node pool

```bash
az aks nodepool get-upgrades \
    --nodepool-name "nodepool1" \
    --cluster-name "myCluster" \
    --resource-group "RG-Lab8"
```

Le résultat est un tableau présentant les montées de versions possible pour Kubernetes

Par défaut les montées de version de Kubernetes dans AKS se font de la manière suivante :
1. Montée de version du Control Plane
2. Montée de version Node Pool par Node Pool
	- Au sein d'un node pool la mise à jour se fait séquentiellement VM après VM
	- Il est possible dans le cas de grands cluster d'accélérer le processus en mettant à jour en simultanée x% des VMs des nodes pools. Le paramètre à modifier est le Node Surge Upgrade. Plus d'informations : https://docs.microsoft.com/en-us/azure/aks/upgrade-cluster?tabs=azure-cli#customize-node-surge-upgrade

Exécuter l'ordre de mise à jour vers une version supérieure de Kubernetes

```bash
az aks upgrade \
    --resource-group "RG-Lab8" \
    --name "myCluster" \
    --kubernetes-version <KUBERNETES_VERSION>
```

Note : les montées de version nécessite de passer par toutes les versions mineures. Il n'est pas possible par exemple de passer directement de la 1.22.1 à la 1.24.

Observer les nodes et les évènements associés dans le cluster via le portail (dans la partie Node Pools) mais aussi via la CLI kubectl

```bash
kubectl get nodes

kubectl get events -n default
```

## Activer les channels de mise à jour automatique (auto-upgrade)

Il est possible d'automatiser les montées de versions à plusieurs niveaux : 
- Au niveau patch. Pour passer automatiquement par exemple de la version 1.2.__4__ à la version 1.2.**5**. C'est le __channel patch__
- Au niveau version mineure : pour passer automatiquement à la version N-1 dernier niveau de patch (N étant la version Kubernetes la plus récente supportée dans Azure). C'est le __channel stable__
- Le __channel rapid__ met à jour le cluster automatiquement avec la version de Kubernetes supporté la plus récente
- Le __channel node-image__ permet d'avoir des VM worker nodes avec la dernière image mise à disposition par l'équipe AKS

Pour configurer le cluster AKS du Lab en mode auto-upgrade, exécuter la commande suivante:

```bash
az aks update --resource-group "RG-Lab8" --name "myCluster" --auto-upgrade-channel rapid -o jsonc
```


## Nettoyage 
Supprimer le resource group RG-Lab8

```bash
az group delete -n "RG-Lab8"
```
