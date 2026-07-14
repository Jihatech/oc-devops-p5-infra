# Projet 5 — Déployez et suivez l'Infrastructure-as-Code avec Terraform, Ansible et ELK

Parcours **Expert DevOps** OpenClassrooms (réf. 4091). Réalisation des 3 exercices en **option
Docker local** (zéro coût, zéro compte AWS), à partir du starter-kit officiel
[`DevOps-4091`](https://github.com/OpenClassrooms-Student-Center/DevOps-4091).

> Dépôt sur **GitHub** (autorisé par le mentor en remplacement de GitLab).

## Pourquoi l'option Docker local ?

Chaque exercice propose deux modes équivalents (Docker local / AWS cloud) validant les mêmes
compétences. L'option Docker a été retenue : **aucun coût**, pas de carte bancaire ni de ressources
cloud à détruire, et un environnement 100 % reproductible sur le poste.

## Plan du dépôt

| Dossier | Contenu |
|---|---|
| [`exercice-1-terraform-ansible/`](./exercice-1-terraform-ansible/) | Terraform (conteneur Nginx 80→8000) + VM cible + playbook Ansible déployant l'app Angular |
| [`exercice-2-elk/`](./exercice-2-elk/) | Stack ELK (docker-compose), log échantillon, guide dashboard + captures |
| [`exercice-3-haproxy/`](./exercice-3-haproxy/) | Load-balancer HAProxy (round-robin + health checks) + docker-compose |
| [`docs/`](./docs/) | Bilans par exercice, preuves d'exécution, journal de pilotage IA |

## Prérequis

- **Docker Desktop** (backend WSL2, virtualisation imbriquée activée → `/dev/kvm`).
- **Terraform** ≥ 1.5.
- **Ansible** exécuté dans un conteneur Docker (`willhallonline/ansible`) — Ansible ne tourne pas
  nativement sous Windows.
- `git` (+ `gh` pour le dépôt distant).

## Reproduction, exercice par exercice

```bash
# --- Exercice 1 : Terraform + Ansible ---
cd exercice-1-terraform-ansible/terraform && terraform init && terraform apply -auto-approve
curl http://localhost:8000                       # nginx (Terraform) : HTTP 200
cd ../vm-cible && terraform init && terraform apply -auto-approve   # VM cible Ubuntu (SSH :2222)
# puis playbook Ansible (voir exercice-1-terraform-ansible/README.md) -> app Angular sur :80

# --- Exercice 2 : ELK ---
cd exercice-2-elk && docker compose up -d        # Kibana :5601, Elasticsearch :9200
# import du log + dashboard : voir exercice-2-elk/README.md

# --- Exercice 3 : HAProxy ---
cd exercice-3-haproxy && docker compose up -d     # app equilibree :8080, stats :8404
```

Chaque sous-dossier contient un `README.md` détaillé. Les bilans (à présenter en session) sont dans
[`docs/`](./docs/) : [BILAN_EX1](./docs/BILAN_EX1.md) · [BILAN_EX2](./docs/BILAN_EX2.md) ·
[BILAN_EX3](./docs/BILAN_EX3.md).

## Sécurité & hygiène

- Aucun secret réel versionné. Le mot de passe de la VM cible (`openclassrooms`) est le **défaut
  public du starter-kit**, fourni au runtime et non stocké dans l'inventaire.
- `.gitignore` exclut l'état Terraform (`*.tfstate`), les répertoires `.terraform/` et les artefacts
  jetables.

## Note de conformité

L'image de la VM cible du starter-kit (`qemux/qemu-docker:5.16`) a été **retirée de Docker Hub**
(projet renommé) ; elle est remplacée par l'image maintenue `qemux/qemu:latest` — seule adaptation
par rapport au starter-kit, documentée dans
[`exercice-1-terraform-ansible/vm-cible/main.tf`](./exercice-1-terraform-ansible/vm-cible/main.tf).
