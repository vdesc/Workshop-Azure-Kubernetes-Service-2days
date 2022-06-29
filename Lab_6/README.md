#
# Lab 6 : 6 : Installation d'AGIC, déploiement d'Azure Application Gateway et déploiement d'une application basique
#
      
--------------------------------------------------------------------------------------------------------

## Objectifs



## Pré-requis sur le poste d'administration

- An Azure Subscription with enough privileges (create RG, AKS...)
- Azure CLI 2.37 or >: <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest>
   And you need to activate features that are still in preview and add extension aks-preview to azure CLI (az extension add --name aks-preview)
- Terraform CLI 1.2.2 or > : <https://www.terraform.io/downloads.html>
- Helm CLI 3.9.0 or > : <https://helm.sh/docs/intro/install/> if you need to test Helm charts


## Préparation de l'environnement AVANT le déploiement avec Terraform

- Ouvrir une session Bash et se connecter à votre abonnement Azure

```bash
az login
```
