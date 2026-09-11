FROM ghcr.io/prefix-dev/pixi:latest

WORKDIR /app
COPY . ./
RUN pixi install --locked && pixi run setup
ENV COAT_URL https://data.coat.no
EXPOSE 3838
CMD [ "pixi", "run", "shiny" ]