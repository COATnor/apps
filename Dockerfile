FROM docker.io/rocker/shiny:4.1.2

RUN --mount=type=cache,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,sharing=locked,target=/var/lib/apt/lists \
    rm -f /etc/apt/apt.conf.d/docker-clean; \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' \
        > /etc/apt/apt.conf.d/keep-cache && \
    apt-get update && \
    apt-get install -qy --no-install-recommends libxml2

RUN rm -rf /srv/shiny-server/* /opt/shiny-server/samples/
WORKDIR /srv/shiny-server

COPY red_fox_tracks/deps.R red_fox_tracks/
RUN Rscript red_fox_tracks/deps.R

COPY small_rodents_abundance/deps.R small_rodents_abundance/
RUN Rscript small_rodents_abundance/deps.R

COPY red_fox_tracks/app.R red_fox_tracks/app.R
COPY red_fox_tracks/www/style.css red_fox_tracks/www/style.css

COPY small_rodents_abundance/app.R small_rodents_abundance/app.R
COPY small_rodents_abundance/www/style.css small_rodents_abundance/www/style.css
