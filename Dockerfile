FROM rocker/shiny:4.1.2

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -qq libxml2

RUN rm -rf /srv/shiny-server/* /opt/shiny-server/samples/
WORKDIR /srv/shiny-server
COPY red_fox_tracks/deps.R red_fox_tracks/
RUN Rscript red_fox_tracks/deps.R
COPY red_fox_tracks/app.R red_fox_tracks/app.R
COPY red_fox_tracks/www/style.css red_fox_tracks/www/style.css
