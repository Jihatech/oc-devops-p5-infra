# Bilan Exercice 2 — Stack ELK (monitoring & logging)

> Option retenue : **Docker local** (docker-compose Elasticsearch 7.14 + Kibana 7.14).

## 1. Rôle de chaque composant de la stack ELK

| Composant | Rôle | Dans cet exercice |
|---|---|---|
| **E — Elasticsearch** | Moteur de recherche et base de données orientée documents (JSON). Il **stocke, indexe et agrège** les données ; c'est lui qui répond aux requêtes analytiques (agrégations, filtres, plein-texte). | Stocke les 14 496 lignes de log parsées dans l'index `nginx-access` et calcule les agrégations des visualisations. |
| **L — Logstash / Beats** | Pipeline d'**ingestion** : collecte, **parse** (ex. grok), transforme et enrichit les données brutes avant de les envoyer à Elasticsearch. | Ici remplacé par la fonction **« Upload file » de Kibana**, qui détecte la structure du log (grok `%{COMBINEDAPACHELOG}`) et crée les champs `verb`, `request`, `bytes`, `response`, `@timestamp`. |
| **K — Kibana** | Interface web de **visualisation et exploration** : Discover, Visualize, Dashboard. Ne stocke rien, interroge Elasticsearch. | Sert à importer le log, explorer dans Discover, et construire le dashboard des 3 visualisations. |

## 2. Interactions entre les composants

```
Fichier nginx-access.log
        │  (Upload file Kibana = rôle d'ingestion type Logstash : grok + parse date)
        ▼
  Elasticsearch  ── indexe & stocke ──►  index "nginx-access"
        ▲                                      │
        │  requêtes d'agrégation (REST/JSON)   │ résultats agrégés
        │                                      ▼
     Kibana  ◄──────── visualisations / dashboard ────────
```

- L'ingestion **parse** le texte brut en champs structurés (le verbe HTTP, l'URL, le volume en
  octets, l'horodatage).
- **Elasticsearch** indexe : chaque champ devient interrogeable et agrégeable en quasi temps réel.
- **Kibana** envoie des requêtes d'agrégation à Elasticsearch et **restitue** le résultat sous
  forme de graphiques ; l'utilisateur n'interagit jamais directement avec Elasticsearch.

## 3. Données de l'échantillon (vérifiées via l'API Elasticsearch)

Pipeline reproduit et testé côté serveur (grok + agrégations) pour valider les configurations du
dashboard **avant** la construction manuelle dans Kibana :

- **Période réelle des données** : `2024-06-24 11:39:38 UTC` → `2024-08-21 13:44:15 UTC`
  → régler le *time picker* Kibana sur **24 juin 2024 → 22 août 2024**.
- **Répartition des verbes HTTP** (donut) : `GET 13003` · `HEAD 1447` · `POST 34` · `PUT 6`.
- **Volume total de données** (`sum(bytes)`) : **≈ 644 Mo** répartis sur **118 tranches de 12 h** ;
  pic le **25/06/2024** (~40,8 Mo).
- **Top 5 des requêtes** : `/` (1992) · `/robots.txt` (1134) · `/articles/zim-web-archive/` (737) ·
  `/favicon.ico` (729) · `/articles/restic-bases/` (703).

Ces valeurs servent de **contrôle** : le dashboard Kibana doit retrouver exactement ces chiffres.

## 4. Livrables

Les 4 captures sont dans [`../exercice-2-elk/captures/`](../exercice-2-elk/captures/) : le dashboard
complet + une capture lisible de chacun des 3 diagrammes. Procédure détaillée de construction :
[`../exercice-2-elk/README.md`](../exercice-2-elk/README.md).
