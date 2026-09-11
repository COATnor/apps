FROM ghcr.io/prefix-dev/pixi:latest

WORKDIR /app
COPY . ./
RUN pixi install --locked
EXPOSE 3838
CMD [ "pixi", "run", "shiny" ]