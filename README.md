# Docker

```bash
docker build -t coat-shiny .
docker run --rm -e lotekpassword=$LOTEKPASSWORD -p 3838:3838 coat-shiny
```
