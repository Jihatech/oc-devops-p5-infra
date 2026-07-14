# Journal de pilotage IA — Projet 5

Traçabilité de l'usage de l'IA (Claude Code) : tâches confiées, revue humaine, correctifs.
Approche : l'IA exécute et **vérifie réellement** (init/apply, ping, curl, agrégations, logs) ;
l'humain pilote, arbitre les choix structurants et produit les livrables non automatisables
(captures Kibana).

## Étape 0 — Environnement & dépôt

| Tâche confiée à l'IA | Résultat / revue | Correctif |
|---|---|---|
| Audit outillage (Docker, Terraform, gh, WSL, Ansible) | Docker 28.5, Terraform 1.15.6, gh authentifié (Jihatech), WSL2+Ubuntu OK, Ansible absent | — |
| Cloner le starter-kit et l'analyser | Fait ; découverte : VM cible = QEMU-in-Docker exigeant `/dev/kvm` | Clone initial en échec (chemin trop long) → re-clone en chemin court + `core.longpaths` |
| Créer le monorepo + repo GitHub | Structure créée, repo public `oc-devops-p5-infra` | Création publique **validée explicitement** par l'humain (garde-fou) avant push |

## Exercice 1 — Terraform & Ansible

| Tâche | Résultat / revue | Correctif |
|---|---|---|
| `main.tf` Nginx 80→8000 + init/plan/apply | `Plan: 2 to add`, apply OK, `curl :8000` HTTP 200 | — |
| Installer Ansible | `pip`/`sudo` indisponibles dans WSL (non interactif) | **Plan B** : Ansible exécuté dans un conteneur Docker (`willhallonline/ansible`) |
| Booter la VM cible | Image starter `qemux/qemu-docker:5.16` retirée de Docker Hub | Substitution par `qemux/qemu:latest` (documentée) ; VM Ubuntu 24.04 bootée, SSH OK |
| Playbook `deploy.yml` (nginx+app+config+handler) | `ping`→pong, `--syntax-check` OK, run `ok=8 changed=7`, handler déclenché, app Angular sur :80 | Host key checking désactivé via env (ansible.cfg ignoré en dossier world-writable) |
| Idempotence | 2e run `changed=0` | — |

## Exercice 2 — Stack ELK

| Tâche | Résultat / revue | Correctif |
|---|---|---|
| Monter la stack ELK | ES `green`, Kibana HTTP 200 | — |
| Déterminer la période réelle & les champs | Via API `find_file_structure` : grok `%{COMBINEDAPACHELOG}`, champs `verb/request/bytes/@timestamp` ; période 24/06→21/08/2024 | Content-Type API corrigé (`application/json`) |
| **Vérifier les 3 agrégations** du dashboard | Données réellement indexées dans un index temporaire ; donut/verbes, sum bytes/12h, top 5 requêtes confirmés puis index supprimé | Bulk curl : chemin `@C:/...` (curl Windows) au lieu de `/c/...` |
| Guide de construction + bilan | `exercice-2-elk/README.md` + `BILAN_EX2.md` avec valeurs de contrôle | — |
| **Captures Kibana (4)** | **À produire par l'humain** (interface graphique non automatisable) | — |

## Exercice 3 — HAProxy

| Tâche | Résultat / revue | Correctif |
|---|---|---|
| `haproxy.cfg` commenté (round-robin + health checks) | Config validée, HAProxy démarré sans erreur | — |
| Test round-robin | Alternance backend prouvée sur 8 requêtes | — |
| Test de panne / réintégration | `stop` → `DOWN (Layer4 timeout)`, bascule ; `start` → `UP (Layer7 200)`, réintégration | — |

## Points de vigilance restants (côté humain)

1. **Produire les 4 captures Kibana** (Exercice 2) — seul livrable non automatisable.
2. Transmettre la **fiche d'autoévaluation** officielle pour pré-remplissage.
3. Penser au `terraform destroy` / `docker compose down` après la session (nettoyage).
