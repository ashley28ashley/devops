# Projet Semestriel : Usine Logicielle & Infrastructure (Local Ops)

## 🎯 Objectif du Projet
L'objectif de ce projet est de construire une usine logicielle complète et une infrastructure simulant un environnement de production d'entreprise en local. La plateforme déploie automatiquement du code, le surveille, et est capable de se réparer seule (auto-healing).

## 🛠️ Stack Technique
* **Application** : Python (Script Worker)
* **Conteneurisation** : Docker (Multi-stage build, Alpine)
* **Orchestration** : Kubernetes (Kind local)
* **Infrastructure as Code (IaC)** : Terraform
* **CI/CD** : GitHub Actions
* **Observabilité** : Prometheus & Grafana (Helm kube-prometheus-stack)
* **Sécurité** : Trivy (Scan de vulnérabilités)

---

## 🚀 Comment lancer le projet (Runbook)

### Prérequis
* [Docker Desktop](https://www.docker.com/products/docker-desktop/) en cours d'exécution.
* [Terraform](https://developer.hashicorp.com/terraform/install) installé.
* [Kind](https://kind.sigs.k8s.io/) (Kubernetes in Docker) installé.
* [Kubectl](https://kubernetes.io/docs/tasks/tools/) installé.

### Démarrage en une seule commande (Mois 3)
Grâce à Terraform, l'infrastructure complète se déploie toute seule :

```bash
cd terraform
terraform init
terraform apply -auto-approve
```
Cette commande va :
1. Créer le cluster Kubernetes local avec `Kind`.
2. Build l'image Docker et l'importer dans le cluster.
3. Déployer les manifestes K8s de l'application et de PostgreSQL.
4. Installer Prometheus et Grafana via Helm.

### Accéder à Grafana (Mois 5)
Une fois le déploiement terminé, ouvre un tunnel vers Grafana :
```bash
kubectl port-forward svc/prometheus-grafana 8080:80 -n monitoring
```
Va sur `http://localhost:8080`
* **User:** `admin`
* **Mot de passe:** Récupère-le dynamiquement avec la commande suivante :
  ```bash
  kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
  ```

---

## 🧠 Choix Techniques & Justifications

1. **Docker Multi-stage & Non-Root (Mois 1)** :
   Le `Dockerfile` compile les dépendances dans un environnement virtuel temporaire (`builder`), puis copie cet environnement propre dans une image finale `Alpine`. L'application tourne avec l'utilisateur restreint `workeruser` pour éviter les failles de sécurité si le conteneur est compromis.

2. **Kubernetes Secrets & Probes (Mois 2)** :
   Les mots de passe ne sont pas hardcodés. Ils sont chiffrés en base64 dans un `Secret` K8s. Des `livenessProbe` ont été ajoutés sur PostgreSQL (`pg_isready`) pour assurer l'auto-healing.

3. **Terraform vs Ansible (Mois 3)** :
   Choix de Terraform avec le provider `tehcyx/kind`. La philosophie d'état (state) de Terraform est parfaite pour s'assurer que le cluster et les configurations Helm sont exactement comme décrit dans les fichiers.

4. **Pipeline CI/CD (Mois 4)** :
   Utilisation de GitHub Actions. Les étapes sont strictement bloquantes : si le linting (`flake8`) ou le test unitaire échoue, le conteneur n'est ni buildé, ni déployé.

5. **Scan de Sécurité (Mois 6)** :
   Intégration de `Trivy` dans le pipeline K8s. Il analyse l'image Docker *juste avant* le déploiement. S'il trouve une faille `CRITICAL`, l'usine logicielle bloque tout déploiement en production.

---

## 📓 Journal de bord & Problèmes rencontrés

* **Problème :** Impossibilité de se connecter à la BDD K8s au début.
  **Résolution :** L'adresse IP de base n'était pas la bonne. Il a fallu utiliser le nom du `Service` K8s (`db`) pour que le DNS interne de Kubernetes fasse la résolution correctement.
* **Problème :** Mots de passe Grafana par défaut (`prom-operator`) qui ne marchent pas.
  **Résolution :** Le chart Helm récent génère automatiquement un mot de passe fort aléatoire. Il a fallu aller extraire le secret Kubernetes généré avec `kubectl get secret`.
* **Problème :** Prometheus ne "trouvait" pas notre worker Python.
  **Résolution :** Création d'un objet `PodMonitor` spécifique (standard Prometheus Operator) pour lier le port `8000` de l'application à Prometheus.
