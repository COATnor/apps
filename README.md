# Docker

```bash
docker build -t coat-shiny .
docker run --rm -e lotekpassword=$LOTEKPASSWORD -e COAT_API=$COAT_API -e COAT_URL=$COAT_URL -p 3838:3838 coat-shiny
```

# pre-commit

```bash
pixi run pre-commit run -a
```