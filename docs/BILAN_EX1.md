# Bilan Exercice 1 — Terraform (IaC) & Ansible (CD)

> Option retenue : **Docker local** (zéro coût, zéro compte AWS). Réponses préparées pour la
> session de bilan (fiche d'autoévaluation officielle).

## 1. Intérêt de Terraform dans la méthodologie DevOps

Terraform est un outil d'**Infrastructure-as-Code (IaC)** : l'infrastructure est décrite dans des
fichiers texte versionnés (HCL) plutôt que créée à la main dans une console.

Apports concrets dans une démarche DevOps :

- **Reproductibilité / idempotence** : le même `main.tf` produit toujours la même infrastructure.
  On supprime la dérive de configuration (« ça marche sur ma machine »).
- **Versionnement & revue** : l'infra vit dans Git, avec pull requests, historique et rollback —
  exactement comme du code applicatif.
- **Approche déclarative** : on décrit l'état *souhaité* ; Terraform calcule le *delta* nécessaire
  (le `plan`) et l'applique. On ne script pas les étapes, on décrit la cible.
- **Multi-provider** : la même logique pilote Docker, AWS, Azure… (ici le provider
  `kreuzwerker/docker`, en AWS ce serait `aws_instance`).
- **Cycle de vie maîtrisé** : `apply` pour créer/mettre à jour, `destroy` pour tout supprimer
  proprement (clé pour éviter les coûts cloud résiduels).

Dans notre `main.tf` : provider `docker` + ressource `docker_image` (`nginx:latest`) +
ressource `docker_container` exposant le port **80 → 8000** de l'hôte.

## 2. Les 3 phases d'un déploiement Terraform

| Phase | Commande | Rôle |
|---|---|---|
| **1. Initialisation** | `terraform init` | Télécharge les *providers* déclarés (ici le provider Docker) et prépare le répertoire de travail (`.terraform/`). À relancer si les providers/backends changent. |
| **2. Planification** | `terraform plan` | Compare l'état souhaité (le code) à l'état réel et affiche le **différentiel** (`+` créations, `~` modifications, `-` destructions) **sans rien appliquer**. Réflexe attendu : *toujours lire le plan avant d'appliquer*. Ici : `Plan: 2 to add`. |
| **3. Application** | `terraform apply` | Exécute le plan et fait converger l'infra réelle vers l'état souhaité, en enregistrant l'état dans `terraform.tfstate`. `terraform destroy` réalise l'opération inverse. |

Preuve d'exécution : voir [`terraform-plan.txt`](./terraform-plan.txt). Vérification post-apply :
`docker ps` (conteneur `oc-p5-nginx`, `0.0.0.0:8000->80/tcp`) + `curl http://localhost:8000`
(HTTP 200, page « Welcome to nginx! »).

## 3. Intérêt d'Ansible pour le déploiement continu et la normalisation

Là où Terraform **provisionne l'infrastructure** (créer la VM), Ansible **configure ce qui tourne
dessus** (installer et paramétrer les logiciels). Les deux sont complémentaires.

- **Déploiement continu (CD)** : le playbook `deploy.yml` déploie l'application de façon
  automatisée et répétable ; on peut le rejouer à chaque nouvelle version sans intervention
  manuelle.
- **Normalisation / cohérence** : le même playbook appliqué à 1 ou 100 serveurs garantit une
  configuration identique partout. Fini les serveurs « pets » configurés à la main.
- **Idempotence** : Ansible n'agit que si l'état diffère de la cible (`changed` vs `ok`). Rejouer
  le playbook ne casse rien et ne modifie que le nécessaire.
- **Agentless** : Ansible se connecte en **SSH**, aucun agent à installer sur les cibles.
- **Handlers** : un `handler` (ici *Redémarrer Nginx*) n'est déclenché **que** lorsqu'une tâche
  `notify` a réellement modifié la configuration → on ne redémarre le service que si besoin.

Structure de notre playbook (3 groupes de tâches + 1 handler) :

1. **Installation de Nginx** (module `apt`) ;
2. **Installation de l'application Angular** `olympic-games-starter` (module `copy` vers
   `/var/www/html/`) ;
3. **Configuration de Nginx** (dépôt du vhost, activation du site, désactivation du site par
   défaut) — chaque changement `notify` le handler ;
4. **Handler** : redémarrage de Nginx uniquement sur changement de configuration.

Validation : `ansible all -i hosts -m ping` → `pong`, `ansible-playbook --syntax-check` propre,
puis `ansible-playbook -i hosts deploy.yml` → l'application Angular répond sur le port 80 de la
cible.

## 4. Terraform vs Ansible — la complémentarité (à savoir expliquer)

| | Terraform | Ansible |
|---|---|---|
| Rôle | **Provisioning** de l'infra (créer/détruire des ressources) | **Configuration** & déploiement applicatif sur l'infra existante |
| Paradigme | Déclaratif, orienté état (state) | Procédural/déclaratif orienté tâches, sans state persistant |
| Cible ici | Le conteneur/VM | Ce qui tourne dans la VM (Nginx + app) |
| Cycle | init → plan → apply → destroy | inventory → ping → playbook |

**Chaîne complète de l'exercice** : Terraform crée la VM cible → Ansible s'y connecte en SSH et y
déploie l'application. C'est le pipeline « infra puis application » typique d'une démarche DevOps.
