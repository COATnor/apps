# Configuration

Each app reads its secrets from a local `.env` file, which is never
committed. Copy the template and fill in the values:

```bash
cp red_fox_tracks/env.template red_fox_tracks/.env
cp small_rodents_abundance/env.template small_rodents_abundance/.env
```

# Docker

```bash
docker compose build
docker compose up
```

Everything is served through Traefik on http://localhost:3838:

- COAT apps index: http://localhost:3838/
- Red fox tracks: http://localhost:3838/red_fox_tracks/
- Small rodents abundance: http://localhost:3838/small_rodents_abundance/

# pre-commit

```bash
pixi run pre-commit run -a
```