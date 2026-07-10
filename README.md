# xlagunas-infra

Reverse proxy i **xarxa compartida** del VPS de `xlagunas.net`.
No conté codi ni apps: només fa córrer **Caddy** i és propietari de la xarxa
Docker `web` on s'hi enganxen totes les aplicacions.

Cada app viu al **seu propi repo**, amb el seu propi `docker-compose.yml`
(app + base de dades + volums), i publica la seva imatge a **GHCR**.

```
Internet ─▶ Caddy (:80/:443, HTTPS auto) ─▶ [xarxa "web"] ─▶ backend d'app-N
                                                                   │
                                                    db ── xarxa "internal" (aïllada)
```

## Patró: infra prima + compose per app

- **Aquest repo**: Caddy + xarxa `web`. Res més.
- **Repo de cada app**: el seu stack complet. El servei web s'enganxa a `web`
  (perquè Caddy hi arribi); la DB queda a una xarxa `internal` privada, invisible
  per al proxy i per a la resta d'apps.

Cada app porta el seu propi `docker-compose.yml` al seu repo (s'enganxa a `web`).

## Ordre d'arrencada al VPS (IMPORTANT)

La infra crea la xarxa `web`, així que va **primer**:

```bash
cd /opt/xlagunas-infra && docker compose up -d # Caddy + xarxa "web"
cd /opt/andrtc_backend && docker compose up -d # l'app s'hi enganxa
```

Si una app arrenca abans i la xarxa `web` no existeix, Docker es queixarà.

## Rutes actives (Caddyfile)

| Subdomini              | → contenidor         |
|------------------------|----------------------|
| `api.viv.xlagunas.net` | `andrtc-backend:8080`|

Afegir una app = un bloc nou al `Caddyfile` + recàrrega en calent:
`docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile`.

## DNS ⚠️ (subdomini de dos nivells)

`api.viv.xlagunas.net` té **dos** nivells sota el domini. Un wildcard
`*.xlagunas.net` **NO** el cobreix (el wildcard només val per a un nivell).
Necessites un dels dos:

```
api.viv.xlagunas.net   A   <IP_DEL_VPS>     # registre explícit (recomanat)
# o bé
*.viv.xlagunas.net     A   <IP_DEL_VPS>     # wildcard per a tot *.viv
```

Caddy demanarà el certificat Let's Encrypt (HTTP-01) la primera visita; només
cal que el DNS apunti al VPS i que els ports 80/443 estiguin oberts.

## Desplegament automàtic (per app)

Cada repo d'app té un workflow (plantilla a `.github/workflows/deploy.yml`) que
en fer push a `main`:

1. build de la imatge,
2. push a `ghcr.io/xlagunas/<app>:latest` (+ `:sha`),
3. SSH al VPS → `cd /opt/<app> && docker compose pull && up -d`.

### Secrets a cada repo d'app

| Secret     | Valor                          |
|------------|--------------------------------|
| `SSH_HOST` | IP o host del VPS              |
| `SSH_USER` | usuari SSH dedicat (no root)   |
| `SSH_KEY`  | clau privada d'aquest usuari   |

## Un cop al VPS

1. Situa aquest repo a `/opt/xlagunas-infra` i cada app al seu `/opt/<app>`.
2. GHCR: si les imatges són privades, `docker login ghcr.io` amb un PAT
   `read:packages`; si són públiques, res.
3. `cd /opt/xlagunas-infra && docker compose up -d`, després aixeca cada app
