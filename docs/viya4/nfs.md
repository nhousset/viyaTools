# Procédure : Configuration du Stockage NFS pour SAS CAS sur Viya 4 (OpenShift)

> ℹ️ **Objectif**
>
> L'objectif de cette procédure est de guider les administrateurs SAS et OpenShift dans la configuration d'un stockage externe NFS pour le serveur SAS Cloud Analytic Services (CAS). Cette configuration est critique pour la persistance des données, le partage de données en mode MPP et la performance globale de la plateforme SAS Viya 4.

> 📝 **Prérequis**
>
> Avant de commencer, assurez-vous que les conditions suivantes sont remplies :
>
> * **Accès au Cluster** : Vous disposez des droits suffisants sur le cluster Red Hat OpenShift pour appliquer des manifestes Kubernetes (généralement `cluster-admin` ou un rôle équivalent pour le namespace cible).
> * **Outils CLI** : Les outils `kubectl` (ou `oc`) et `kustomize` (version compatible avec votre déploiement Viya) sont installés et configurés sur votre poste de travail.
> * **Répertoire de déploiement** : Vous avez accès au répertoire de déploiement SAS Viya (ci-après désigné par la variable `$deploy`).
> * **Serveur NFS** :
>     * L'adresse IP ou le FQDN du serveur NFS est connu.
>     * Le chemin d'export du partage NFS est connu (ex: `/exports/casdata`).
>     * La connectivité réseau entre les nœuds du cluster OpenShift et le serveur NFS est établie et fonctionnelle.
>     * Les permissions d'export NFS sont configurées pour autoriser l'accès en lecture/écriture (`rw`) depuis les nœuds du cluster.

---

## Procédure de Configuration

### Étape 1 : Préparation de l'Espace de Travail

Cette étape consiste à préparer les fichiers de personnalisation dans le répertoire `site-config`.

1.  **Créer un répertoire de configuration** : Pour une meilleure organisation, créez un sous-répertoire dédié au stockage CAS.
    ```bash
    # Exécuter cette commande à la racine de votre répertoire de déploiement ($deploy)
    mkdir -p site-config/cas-nfs-storage
    ```

2.  **Copier le fichier de transformation** : Copiez le modèle de transformation fourni par SAS depuis le répertoire `sas-bases` vers votre répertoire de configuration.
    ```bash
    # Exécuter cette commande à la racine de votre répertoire de déploiement ($deploy)
    cp sas-bases/examples/cas/configure/cas-add-nfs-mount.yaml site-config/cas-nfs-storage/
    ```

### Étape 2 : Personnalisation du Transformateur NFS

Modifiez le fichier copié pour qu'il corresponde à votre environnement NFS.

1.  **Ouvrir le fichier** :
    Éditez le fichier `site-config/cas-nfs-storage/cas-add-nfs-mount.yaml`.

2.  **Modifier le fichier** :
    Repérez les variables `{{ NFS-SERVER-NAME }}` et `{{ NFS-PATH }}` et remplacez-les par les valeurs de votre environnement.

    > 💡 **Note**
    >
    > Le `mountPath` (ex: `/cas/nfs-data`) est le chemin que les utilisateurs ou administrateurs SAS utiliseront pour définir des caslibs de type PATH. Choisissez un nom descriptif.

    *Exemple de fichier `cas-add-nfs-mount.yaml` modifié :*
    ```yaml
    # Fichier : site-config/cas-nfs-storage/cas-add-nfs-mount.yaml
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: cas-add-nfs-mount-transformer
    patch: |-
      # Définition du volume NFS
      - op: add
        path: /spec/controllerTemplate/spec/volumes/-
        value:
          name: cas-nfs-persistent-storage
          nfs:
            # Remplacer par le FQDN ou l'IP de votre serveur NFS
            server: 'nfs-server.votre-domaine.com'
            # Remplacer par le chemin du partage sur le serveur NFS
            path: '/exports/viya/casdata'
      # Point de montage pour le contrôleur CAS
      - op: add
        path: /spec/controllerTemplate/spec/containers/0/volumeMounts/-
        value:
          name: cas-nfs-persistent-storage
          # Chemin d'accès à l'intérieur du pod
          mountPath: /cas/nfs-data
      # Répéter les opérations pour les workers CAS (s'ils existent dans le template)
      - op: add
        path: /spec/workerTemplate/spec/volumes/-
        value:
          name: cas-nfs-persistent-storage
          nfs:
            server: 'nfs-server.votre-domaine.com'
            path: '/exports/viya/casdata'
      - op: add
        path: /spec/workerTemplate/spec/containers/0/volumeMounts/-
        value:
          name: cas-nfs-persistent-storage
          mountPath: /cas/nfs-data
    target:
      # Cible la ressource de déploiement CAS
      kind: CASDeployment
      name: .*
    ```

### Étape 3 : Intégration dans Kustomize

Déclarez le nouveau fichier de transformation dans le fichier `kustomization.yaml` principal.

1.  **Ouvrir le fichier `kustomization.yaml`** situé à la racine de votre répertoire de déploiement (`$deploy`).

2.  **Localiser la section `transformers:`**.

3.  **Ajouter la référence** au chemin relatif de votre fichier de transformation.

    > ⚠️ **Attention**
    >
    > L'ordre est crucial. La référence à votre transformateur personnalisé doit être placée **avant** la ligne des transformateurs par défaut (`sas-bases/overlays/required/transformers.yaml`).

    *Exemple de section `transformers:` modifiée :*
    ```yaml
    # Fichier : kustomization.yaml
    ...
    transformers:
    # Ajouter la ligne suivante :
    - site-config/cas-nfs-storage/cas-add-nfs-mount.yaml
    
    # Lignes existantes
    - sas-bases/overlays/required/transformers.yaml
    ...
    ```

---

## Déploiement et Vérification

### Étape 4 : Application des Modifications

1.  **Générer le manifeste complet** : Naviguez jusqu'à la racine de votre répertoire `$deploy` et exécutez la commande `kustomize build`.
    ```bash
    kustomize build -o site.yaml
    ```

2.  **Appliquer le manifeste au cluster** :
    ```bash
    # Remplacer <namespace> par le nom de votre namespace SAS Viya
    kubectl apply -f site.yaml -n <namespace>
    ```
    Cette action déclenchera une mise à jour du déploiement CAS. Les anciens pods seront terminés et de nouveaux seront créés avec la nouvelle configuration de stockage.

### Étape 5 : Vérification Post-Déploiement

Validez que la configuration a été correctement appliquée.

1.  **Vérifier le statut des pods CAS** :
    ```bash
    kubectl get pods -n <namespace> -l [sas.com/deployment-component=cas](https://sas.com/deployment-component=cas)
    ```
    Assurez-vous que tous les pods CAS (contrôleur et workers) redémarrent et atteignent le statut `Running`. En cas d'erreur (`Error` ou `CrashLoopBackOff`), consultez les logs avec `kubectl logs <nom-du-pod> -n <namespace>`.

2.  **Inspecter la configuration du pod** :
    Vérifiez qu'un pod CAS a bien le volume NFS monté.
    ```bash
    kubectl describe pod <nom-du-pod-cas-controller> -n <namespace>
    ```
    Dans la sortie, vérifiez les sections `Volumes` et `Containers -> Mounts` pour retrouver la définition de votre volume `cas-nfs-persistent-storage`.

3.  **Effectuer un test fonctionnel** :
    * Connectez-vous à **SAS Environment Manager**.
    * Naviguez vers la section **Données** -> **Serveurs CAS**.
    * Créez une nouvelle **Caslib** avec les paramètres suivants :
        * **Type** : `PATH`.
        * **Source Path** : `/cas/nfs-data` (ou le `mountPath` que vous avez configuré).
        * **Persistance** : Activez la persistance.
    * Sauvegardez la caslib, puis essayez de charger un fichier ou d'y écrire une table pour confirmer que l'accès en lecture/écriture est fonctionnel.
