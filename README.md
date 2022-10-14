# Docker

```bash
docker build -t coat-shiny .
docker run --rm -e lotekpassword=$LOTEKPASSWORD -e API_coat=$API_COAT -p 3838:3838 coat-shiny
```
