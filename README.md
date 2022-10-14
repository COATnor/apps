# Docker

```bash
docker build -t coat-shiny .
docker run --rm -e lotekpassword=$LOTEKPASSWORD -e COAT_API=$COAT_API -p 3838:3838 coat-shiny
```
