# Exercice 3 — Load-balancer HAProxy · option Docker local

1 HAProxy répartit le trafic HTTP en **round-robin** sur 2 serveurs `nginxdemos/hello`, avec
**health checks** HTTP et **failover / réintégration** automatiques.

```
Navigateur ──HTTP:8080──► HAProxy ──round-robin──► webserver1 / webserver2
```

## Démarrer

```bash
cd exercice-3-haproxy
docker compose up -d
```

- Application équilibrée : http://localhost:8080 (rafraîchir → le backend servi alterne)
- Statistiques HAProxy : http://localhost:8404

## Vérifier le round-robin

```bash
for i in $(seq 1 8); do curl -s http://localhost:8080 | grep -oE '172\.[0-9.]+' | head -1; done
# => l'adresse alterne entre les 2 backends
```

## Test de panne / réintégration

```bash
docker stop webserver1     # HAProxy detecte "DOWN" (Layer4 timeout) -> tout passe sur webserver2
docker compose logs haproxy | grep -E "DOWN|UP"
docker start webserver1    # HAProxy detecte "UP" (Layer7 check 200) -> round-robin repris
```

Résultats et logs consignés : [`../docs/haproxy-failover.txt`](../docs/haproxy-failover.txt) et
analyse dans [`../docs/BILAN_EX3.md`](../docs/BILAN_EX3.md).

## Configuration

Le fichier **[`haproxy.cfg`](./haproxy.cfg)** est le livrable clé : chaque directive importante y est
commentée (round-robin, `option httpchk`, `inter/fall/rise`, timeouts).

## Nettoyage

```bash
docker compose down -v --remove-orphans
```
