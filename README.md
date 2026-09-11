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