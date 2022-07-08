# Lab 7 - Utilisation du Secret Store CSI Driver avec Azure Key Vault

## Objectifs
Utiliser le  provider Azure Key Vault pour le Secret Store CSI Driver afin d'intégrer Azure Key Vault comme magasin de secrets dans un cluster AKs via les volumes CSI.

Ce lab va consister à mettre des secrets dans un Azure Key Vault et à les exposer dans le système de fichier d'un Pod dans Kubernetes

Lectures additionnelles:
[Kubernetes Container Storage Interface (CSI) Documentation](https://kubernetes-csi.github.io/docs/#kubernetes-container-storage-interface-csi-documentation)

## Pré-requis sur le poste d'administration

-   Un abonnement Azure avec les privilèges d'administration (idéalement owner)
-   Azure CLI 2.37 or >: [https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) 
-   kubectl

Les opérations sont réalisables depuis l'Azure Cloud Shell : [https://shell.azure.com](https://shell.azure.com/)

## Création d'un cluster AKS pour le lab

```bash
az login

az group create --name "RG-Lab7" --location "eastus2"

az aks create -n "myCluster" -g "RG-Lab7" --network-plugin azure --enable-addons azure-keyvault-secrets-provider --enable-managed-identity --location "eastus2"  

az aks get-credentials -n "myCluster" -g "RG-Lab7" 
```

Une user-managed identity appelée *azurekeyvaultsecretsprovider-*  a été créée par le add-on. Elle va permettre d'accéder à des ressources Azure.

## Vérification de la bonne installation de l'Azure Key Vault Provider for Secret Store CSI Driver
```bash
kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver, secrets-store-provider-azure)' -o wide
```

Pour chaque noeud du cluster, Il doit y avoir un pod Secret Store CSI driver et un pod Azure Key Vault Provider 

## Création d'un Azure Key Vault et de secrets

```bash 
az keyvault create -n "Choisirunnomunique" -g "RG-Lab7" -l "eastus2"
```

Vérifier que le keyvault est bien créé:

```bash
az keyvault list -g "RG-Lab7 -o table"
```

Créer un secret dans l'Azure Key Vault. 

Rappel : un secret dans Azure Key Vault est une chaine de caractères. Les secrets d'Azure Key Vault peuvent servir pour stocker des mots de passe, des chaines de connexion, des clés d'API... 

```bash
az keyvault secret set --vault-name "<keyvault-name>" -n "MonSecret" --value "SaisirIciunSecret"
```

Lecture additionnelle:
Azure Key Vault keys, secrets and certificates overview : https://docs.microsoft.com/en-us/azure/key-vault/general/about-keys-secrets-certificates
About Azure Key Vault secrets : https://docs.microsoft.com/en-us/azure/key-vault/secrets/about-secrets

## Choix d'une identité pour accéder à l'Azure Key Vault
Le CSI Secret Store Driver peut s'authentifier auprès de l'Azure Key Vault via les méthodes suivantes :
- Une Azure Active Directory Pod Identity
- Une user-assigned identity
- Une system-assigned identity

Pour ce lab, l'authentification du Secret Store Driver auprès de l'Azure Key Vault se fera avec la user managed identity du Secret Store Driver

Pour avoir l'ensemble des informations sur le cluster, exécuter la commande suivante et rechercher les différentes identités 

```bash
az aks show --resource-group "RG-Lab7" --name "myCluster" -o jsonc
```

Parcourir le résultat de la commande et noter la présence d'une user-managed identity pour le secret store Driver

Récupérer l'id de la managed identity associée à l'Azure Key Vault Secret Provider

```bash
az aks show -g "RG-Lab7" -n "myCluster" --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv
```

La liste des user managed identities associées à un VMSS est disponible via la commande:

```bash
az vmss identity show -g MC_RG-Lab7_myCluster_eastus2  -n aks-nodepool1-XXXXXXX-vmss -o jsonc
```



## Affection des permissions pour la managed identity sur l'Azure Key Vault

Il faut donner les droits d'accès aux informations contenues dans l'Azure Key Vault à la managed identity

Pour ce lab, le but est d'utiliser un secret.

```bash
# set policy to access keys in your key vault
az keyvault set-policy -n "<keyvault-name>" --secret-permissions get --spn "<identity-client-id>"
```

Si il y a besoin d'accéder à des clés ou des certificats dans l'Azure Key Vault, alors exécuter les commandes suivantes :

```bash
# set policy to access secrets in your key vault
az keyvault set-policy -n <keyvault-name> --secret-permissions get --spn <identity-client-id>
# set policy to access certs in your key vault
az keyvault set-policy -n <keyvault-name> --certificate-permissions get --spn <identity-client-id>
```

## Création d'une SecretProviderClass

Récupérer l'Id du tenant associé à la subscription Azure

```bash
az account list -o jsonc
```

Editer le fichier SecretProviderClass.yaml  

```yml
# This is a SecretProviderClass example using user-assigned identity to access your key vault
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kvname-user-msi
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"          # Set to true for using managed identity
    userAssignedIdentityID: <client-id>   # Set the clientID of the user-assigned managed identity to use
    keyvaultName: <key-vault-name>        # Set to the name of your key vault
    cloudName: ""                         # [OPTIONAL for Azure] if not provided, the Azure environment defaults to AzurePublicCloud
    objects:  |
      array:
        - |
          objectName: secret1
          objectType: secret              # object types: secret, key, or cert
          objectVersion: ""               # [OPTIONAL] object versions, default to latest if empty
        - |
          objectName: key1
          objectType: key
          objectVersion: ""
    tenantId: <tenant-id>                 # The tenant ID of the key vault
```

Puis modifier les valeurs avec :
- l'id de la user managed identity (client-id)
- le nom du keyvault
- le nom du secret : MonSecret
- l'id du tenant (=ID de l'Azure Active Directory)

Sauvegarder les modifications effectués sur le fichier yaml.

Appliquer la configuration dans le cluster Kubernetes:

```bash
kubectl apply -f SecretProviderClass.yaml
```

## Vérification du bon fonctionnement du CSI Secret Store Driver

Appliquer le manifest Kubernetes pod.yaml


```yaml
# This is a sample pod definition for using SecretProviderClass and the user-assigned identity to access your key vault
kind: Pod
apiVersion: v1
metadata:
  name: busybox-secrets-store-inline-user-msi
spec:
  containers:
    - name: busybox
      image: k8s.gcr.io/e2e-test-images/busybox:1.29-1
      command:
        - "/bin/sleep"
        - "10000"
      volumeMounts:
      - name: secrets-store01-inline
        mountPath: "/mnt/secrets-store"
        readOnly: true
  volumes:
    - name: secrets-store01-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: "azure-kvname-user-msi"
```


```bash 
kubectl apply -f pod.yaml 

kubectl get pods
```

Une fois que le pod est démarré (état Running), le secret doit être monté dans le chemin configuré précédemment

```bash
## show secrets held in secrets-store
kubectl exec busybox-secrets-store-inline-user-msi -- ls /mnt/secrets-store/

## print a test secret 'ExampleSecret' held in secrets-store
kubectl exec busybox-secrets-store-inline-user-msi -- cat /mnt/secrets-store/MonSecret
```

Lectures additionnelles:
- CSI Secret Store Identity Access : https://docs.microsoft.com/en-us/azure/aks/csi-secrets-store-identity-access

## Nettoyage 
Supprimer le resource group RG-LabX

```bash
az group delete -n "RG-Lab7"
```
