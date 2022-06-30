# Workshop-Azure-Kubernetes-Service-2days
Workshop de 2 jours autour de d'Azure Kubernetes Services et services associés

tags: #workshop #aks #github #kubernetes

<img width='800' src='./images/Banner-workshop.jpg'/> 


## Objectifs
Découverte de Kubernetes dans Azure avec des exercices pratiques

## Agenda
### jour 1
#### matinée
- Introduction de l'atelier, programme des 2 journées
- Rappels rapides sur les architectures cloud natives, 12 factors apps, pet vs cattle, baking vs frying....
- Rappels rapides sur les basiques de Kubernetes
- Présentation AKS : control plane, worker nodes, réseau, stockage
- Lab 1 : création d'un cluster AKS via le portail Azure + visualisation des ressources via le portail Azure 
- Lab 2 : création d'un cluster plus avancé via Azure CLI, connexion et utilisation basique de kubectl
- Lab 3 : création d'un cluster avec plusieurs node pools avec autoscaling via Terraform + déploiement basique d'une application (service de type load balancer)
### Après midi
- Intégration avec d'autres services Azure : Azure Monitor, Azure Policy, Azure Container Registry, Azure Log Anaytics, Azure Application Gateway, Azure NAT Gateway, Microsoft Defender for Cloud...
- Lab 4 : Activation du monitoring avec Azure Monitor
- Lab 5 : Azure Container Registry : configuration, importation et utilisation avec AKS 
- Lab 6 : Installation d'AGIC, déploiement d'Azure Application Gateway et déploiement d'une application basique
- Lab 7 : Utilisation du Secret Store CSI Driver avec Azure Key Vault


## Jour 2
### matinée
- Gestion des montées de version :  du cluster à l'application 
- Lab 8 : Montées de version du cluster (stan)
- Lab 9 : Montées de version de l'application (Pierre)  => Rolling update, Blue Green, Canary
- Automatisation des déploiements applicatifs et configurations Kubernetes : Deployment Center, Pipelines avec GitHub, GitOps, Kustomize
- Lab 10 : Pipeline CI/CD Kubernetes YAML 
### après midi
- Lab 11 : Pipline avec Kustomize (Pierre)
- Lab 12 : GitOps avec AKS et Fluxv2 
- Autoscaling quelles options ? HPA, KEDA, Virtual Kubelet...
- Conclusion - Tour de table

## Pré requis - compétences
- Connaissances basiques de Kubernetes : à minima regarder les vidéos suivantes : https://www.youtube.com/watch?v=Srsabd1J-KU et https://www.youtube.com/watch?v=we7prqhRRHA
- Connaissances basiques d'Azure (RG, Azure CLI, RBAC, Service Principal)
- Connaissances basiques de git
- Connaissance basiques Bash

## Pré requis - techniques
- Un Abonnement Azure avec des privilèges d'administrateur
- Un compte GitHub

## Optionnel (les labs peuvent être réalisés depuis l'Azure Cloud Shell)
- un shell Bash
- Azure CLI
- git
- kubectl
- helm
- terraform 
- VS Code
