# Exercice 1 — Terraform (IaC) & Ansible (CD) · option Docker local

Déploiement en deux temps : **Terraform** provisionne l'infrastructure, **Ansible** y déploie
l'application Angular `olympic-games-starter`.

```
exercice-1-terraform-ansible/
├── terraform/        # main.tf graduable : conteneur Nginx 80 -> 8000 (partie Terraform)
├── vm-cible/         # recette Terraform du starter-kit : VM Ubuntu 24.04 (QEMU) cible d'Ansible
└── ansible/          # inventaire, playbook deploy.yml, app Angular, config nginx
```

## Prérequis

- Docker Desktop (backend WSL2) avec **virtualisation imbriquée** → `/dev/kvm` disponible
  (requis par la VM QEMU cible).
- Terraform ≥ 1.5.
- **Ansible ne tourne pas nativement sous Windows** → il est exécuté dans un conteneur Docker
  (`willhallonline/ansible`). C'est le **plan B** prévu par la consigne (WSL présent mais sans
  `pip`/`sudo` non interactif ici).

## Partie 1 — Terraform : conteneur Nginx (port 80 → 8000)

```bash
cd terraform
terraform fmt
terraform init
terraform plan          # lire le plan : "Plan: 2 to add"
terraform apply -auto-approve
docker ps                       # oc-p5-nginx  0.0.0.0:8000->80/tcp
curl http://localhost:8000      # HTTP 200, "Welcome to nginx!"
```

Preuve du plan : [`../docs/terraform-plan.txt`](../docs/terraform-plan.txt).

## Partie 2a — Démarrer la VM cible (Terraform)

> ⚠️ Le starter-kit référence l'image `qemux/qemu-docker:5.16`, **retirée de Docker Hub**
> (projet renommé). On utilise l'image maintenue **`qemux/qemu:latest`** — seule ligne modifiée
> dans `vm-cible/main.tf`.

```bash
cd vm-cible
terraform init
terraform apply -auto-approve
docker logs -f openclassrooms-p5-edo   # attendre "Ubuntu 24.04 LTS openclassrooms ttyS0"
# SSH : ssh -o PreferredAuthentications=password openclassrooms@127.0.0.1 -p 2222  (mdp: openclassrooms)
```

La VM publie : `80` (HTTP app), `8006` (console VNC web), `2222` → `22` (SSH).

## Partie 2b — Ansible : déployer l'application

L'inventaire cible `host.docker.internal:2222` (la VM vue depuis le conteneur Ansible). Le mot de
passe (`openclassrooms`, défaut public du starter-kit) est passé au runtime, **non versionné**.

```bash
# Depuis le dossier ansible/ (adapter le chemin monté) :
ANS="docker run --rm --add-host=host.docker.internal:host-gateway \
  -e ANSIBLE_HOST_KEY_CHECKING=False -v $PWD:/work -w /work willhallonline/ansible:latest"

# Test de connectivité
$ANS ansible all -i hosts -m ping -e ansible_password=openclassrooms          # => pong
# Contrôle syntaxique
$ANS ansible-playbook --syntax-check deploy.yml
# Déploiement
$ANS ansible-playbook -i hosts deploy.yml -e ansible_password=openclassrooms   # ok=8 changed=7
curl http://localhost:80        # HTTP 200, "Olympic Games App"
```

Preuves d'exécution (ping, idempotence, page servie) : [`../docs/ansible-run.txt`](../docs/ansible-run.txt).

## Nettoyage

```bash
cd terraform && terraform destroy -auto-approve
cd ../vm-cible && terraform destroy -auto-approve
```
