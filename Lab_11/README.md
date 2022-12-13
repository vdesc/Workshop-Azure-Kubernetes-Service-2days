## Lab 11 : Pipeline avec Kustomize
## Objectif:
Kustomize est un outil Kubernetes qui vous permet de personnaliser les fichiers YAML bruts de vos ressources k8s d'origine à des fins multiples (ex: différents environnements, différentes variables/répliques/ressources informatiques, etc ...), en laissant les fichiers YAML d'origines intacts et utilisables tels quels.<br>
L'objectif de ce Lab 11, c'est d'utiliser Kustomize pour générer un fichier de configuration avec des paramètres à partir de plusieurs fichiers manisfestes sans les modifier. <br>
https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/
1. **Création de l'environnement de démonstration** <br>
**_Déploiement du "resource group":_**
```
az group create \
    --location "eastus2" \
    --resource-group "RG-AKS-Lab-11"
```
**_Déploiement d'un virtual network:_**
```
az network vnet create \
    --resource-group "RG-AKS-Lab-11" \
    --name AKSvnet \
    --location "eastus2" \
    --address-prefixes 10.0.0.0/8
```
**_Déploiement du subnet_:**
```
SUBNET_ID=$(az network vnet subnet create \
    --resource-group "RG-AKS-Lab-11" \
    --vnet-name AKSvnet \
    --name subnetAKS \
    --address-prefixes 10.240.0.0/16 \
    --query id \
    --output tsv)
```
**_Création d'une "Managed Identity":_**
```
IDENTITY_ID=$(az identity create \
    --resource-group "RG-AKS-Lab-11" \
    --name idAks \
    --location "eastus2" \
    --query id \
    --output tsv)
```
**_Création du "cluster AKS":_**
```
az aks create \
    --resource-group "RG-AKS-Lab-11" \
    --name "AKS-Lab-11" \
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
    --yes
```
2. **Sans Kustomize** <br>
Regarder les manifestes:<br>
- ./Manifest/base/deployment.yaml
- ./Manifest/base/service.yaml
- ./Manifest/base/namespace.yaml

Tout le lab se fera depuis ./Manifest

Création des ressources:<br>
`az aks get-credentials --resource-group RG-AKS-Lab-11 --name AKS-Lab-11`<br>
`kubectl apply -f base/`(Vous serez peut être obligé de lancer deux fois la commande)<br>
Vérifications:<br>
`kubectl get deploy --namespace test-kustomize`<br>
```
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
http-test-kustomize   1/1     1            1           13m
```
`kubectl get service --namespace test-kustomize`<br>
```
NAME                  TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE
http-test-kustomize   LoadBalancer   10.0.6.249   20.22.64.91   80:32130/TCP   60s
```
Test:<br>
```
curl htt://<EXTERNAL-IP>
```
Ok on supprime:<br>
`kubectl delete -f base/`
```
deployment.apps "http-test-kustomize" deleted
namespace "test-kustomize" deleted
service "http-test-kustomize" deleted
```
3. **Avec Kustomize**<br>
Modifier les fichiers `deployment.yaml` et `service.yaml`<br>
Pour le fichier `deployment.yaml`:<br>
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: http-test-kustomize
spec:
  template:
    spec:
      containers:
      - name: http-test-kustomize
        image: nginx
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
```
Pour le fichier `service.yaml`:<br>
```
apiVersion: v1
kind: Service
metadata:
  name: http-test-kustomize
spec:
  type: LoadBalancer
  ports:
    - name: http
      port: 80
```
Les fichiers ne seront jamais modifiés, on applique simplement une personnalisation au-dessus d'eux grâce à l'outil kustomize pour créer de nouvelles définitions des ressources.<br>
Créez un fichier `kustomization.yaml` au même niveau que `service.yaml` et `deployment.yaml`<br>
`kustomization.yaml`:<br>
```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: test-kustomize
commonLabels:
  app: http-test-kustomize

resources:
  - service.yaml
  - deployment.yaml
  - namespace.yaml
```

On doit avoir une arborescence:<br>
```
|__ base
    |__ deployment.yaml
    |__ namespace.yaml
    |__ service.yaml
    |__ kustomization.yaml
```
Vérification du YAML qui sera généré:<br>
`kubectl kustomize ./base`<br>
Les Labels,Selectors et le namespace ont été générés ...<br>
Application de la configuration:<br>
`kubectl apply -k base`<br>
Test:<br>
`kubectl get service --namespace test-kustomize`<br>
`curl htt://<EXTERNAL-IP>`

on supprime :<br>
`kubectl delete -k base`<br>

3. **Pipeline avec Kustomize**<br>
A partir d'ici on est dans GitHub, on modifie dans le repo<br>
Modifier les fichiers `deployment.yaml` et `service.yaml` (comme précédement)<br>
Modifiez le fichier `kustomization.yaml`<br>
```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: mon-namespace
commonLabels:
  app: mon-app

resources:
  - service.yaml
  - deployment.yaml
  - namespace.yaml
```
Allez dans le workflow ./github/workflows/kustomize.yaml<br>
Observer le workflow<br>
Modifiez le et executez le <br>

4. **Fin du Lab**<br>
az group delete --name RG-AKS-Lab-11






