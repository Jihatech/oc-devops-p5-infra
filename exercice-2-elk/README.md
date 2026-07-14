# Exercice 2 — Stack ELK · guide de construction du dashboard

> Option Docker local. La stack et l'ingestion ont été **validées de bout en bout via l'API
> Elasticsearch** (voir [`../docs/BILAN_EX2.md`](../docs/BILAN_EX2.md)). Les **4 captures d'écran**
> restent à produire dans Kibana (interface graphique) — c'est le livrable de l'exercice.

## 0. Démarrer la stack

```bash
cd exercice-2-elk
docker compose up -d
# Elasticsearch : http://localhost:9200   |   Kibana : http://localhost:5601  (attendre ~1-2 min)
```

## 1. Importer le log → index `nginx-access`

1. Kibana → menu ☰ → **Machine Learning → Data Visualizer**, ou page d'accueil → **« Upload a file »**.
2. Glisser `samples/nginx-access.log`. Kibana détecte automatiquement le format
   (`%{COMBINEDAPACHELOG}`) et propose les champs `verb`, `request`, `bytes`, `response`,
   `clientip`, `@timestamp`.
3. **Import** → **Advanced** → nommer l'index **`nginx-access`** → *Create index pattern* coché →
   **Import**.
4. À l'issue, l'*index pattern* `nginx-access` doit exister avec `@timestamp` comme champ temporel.

## 2. Régler l'intervalle de temps (⚠️ crucial)

En haut à droite (time picker) → **Absolute** → du **24 juin 2024 00:00** au **22 août 2024 00:00**.
Sans cela, les graphiques apparaissent vides (les données datent de l'été 2024).

Vérifier dans **Discover** : ~**14 496** documents sur la période.

## 3. Construire les 3 visualisations (Visualize Library → Create visualization → *Aggregation based*)

### ① Donut — répartition des verbes HTTP
- Type **Pie**. Metric : **Slice size = Count**.
- Buckets → **Split slices** → Aggregation **Terms** → Field **`verb`** → Size **5**.
- Options → cocher **Donut**. → **Save** sous `donut-verbes-http`.
- Contrôle attendu : GET 13003 · HEAD 1447 · POST 34 · PUT 6.

### ② Histogramme — volume de données envoyées par tranches de 12 h
- Type **Vertical bar**. Y-axis → Aggregation **Sum** → Field **`bytes`**.
- X-axis → **Date Histogram** → Field **`@timestamp`** → **Minimum interval = Custom → `12h`**.
- **Save** sous `histogramme-data-12h`.
- Contrôle attendu : total ≈ 644 Mo, pic le 25/06/2024 (~40,8 Mo).

### ③ Histogramme cumulé — top 5 des requêtes par tranches de 12 h
- Type **Vertical bar**. Y-axis → Aggregation **Count**.
- X-axis → **Date Histogram** → **`@timestamp`** → interval **`12h`**.
- Ajouter un bucket **Split series** → **Terms** → Field **`request`** → Size **5**
  (ordonné par Count desc).
- Barres **empilées** (« cumulé ») — c'est le mode par défaut du *Vertical bar* avec split series.
  *(Variante « somme cumulée dans le temps » : métrique Count puis pipeline **Cumulative Sum** —
  au choix selon la lecture attendue.)*
- **Save** sous `histogramme-top5-12h`.
- Contrôle attendu (top 5) : `/` · `/robots.txt` · `/articles/zim-web-archive/` · `/favicon.ico` ·
  `/articles/restic-bases/`.

## 4. Dashboard + captures

1. **Dashboard → Create dashboard → Add** les 3 visualisations → arranger → **Save** (`nginx-access`).
2. Vérifier que le time picker est bien sur 24/06 → 22/08/2024.
3. Prendre **4 captures** dans `captures/` :
   - `dashboard.png` — le dashboard complet ;
   - `donut-verbes-http.png` ;
   - `histogramme-data-12h.png` ;
   - `histogramme-top5-12h.png`.

## 5. Nettoyage

```bash
docker compose down --remove-orphans -v
```
