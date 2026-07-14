# Bilan Exercice 3 — Load-balancer HAProxy (haute disponibilité)

> Option Docker local : 1 conteneur `haproxy:2.3` + 2 conteneurs `nginxdemos/hello`.
> Livrable clé : [`../exercice-3-haproxy/haproxy.cfg`](../exercice-3-haproxy/haproxy.cfg) (commenté).

## 1. Load balancing round-robin (vérifié)

`balance roundrobin` dans le backend : chaque requête est servie alternativement par un serveur
différent. Test sur 8 requêtes (`curl http://localhost:8080`) — l'adresse du backend alterne :

```
172.20.0.3 (webserver1) ↔ 172.20.0.2 (webserver2)  à chaque requête
```

## 2. Health checks

- `option httpchk GET /` + `http-check expect status 200` : sonde **HTTP applicative** (couche 7)
  — un serveur n'est « sain » que s'il répond réellement `200 OK`, pas seulement si le port TCP
  est ouvert.
- `default-server inter 2s fall 3 rise 2` :
  - `inter 2s` : une sonde toutes les 2 secondes ;
  - `fall 3` : 3 échecs consécutifs → serveur marqué **DOWN** ;
  - `rise 2` : 2 succès consécutifs → serveur **réintégré (UP)**.

### Optimisations choisies (à expliquer en bilan)

Le réglage est un **compromis sensibilité / stabilité** :
- `inter 2s` + `fall 3` ⇒ panne détectée en ~6 s : assez réactif pour ne pas servir longtemps un
  serveur mort, sans être au point de réagir au moindre hoquet réseau (ce qui provoquerait de
  **fausses alertes** / battement `flapping`).
- `rise 2` évite de réinjecter un serveur qui ne répondrait qu'une fois par hasard.
- Une sonde **HTTP (L7)** est préférée à un simple check **TCP (L4)** : elle détecte aussi le cas
  « port ouvert mais application en erreur 500 ».

## 3. Test de panne réel et réintégration (vérifié)

Séquence complète et logs dans [`haproxy-failover.txt`](./haproxy-failover.txt).

| Étape | Observation |
|---|---|
| `docker stop webserver1` | HAProxy : `Server web_servers/webserver1 is DOWN, reason: Layer4 timeout`. Tout le trafic bascule sur webserver2 (172.20.0.2) — **service ininterrompu**. |
| `docker start webserver1` | HAProxy : `Server web_servers/webserver1 is UP, reason: Layer7 check passed, code: 200`. La répartition round-robin reprend automatiquement sur les 2 serveurs. |

La bascule (**failover**) et la **réintégration automatique** sont donc démontrées : c'est le
principe de la **haute disponibilité** — aucune intervention manuelle, aucune coupure de service
côté client.

## 4. Page de statistiques

Une interface de stats HAProxy est exposée sur `http://localhost:8404` (`stats enable`) : elle
montre en temps réel l'état UP/DOWN de chaque serveur et les compteurs de requêtes.
