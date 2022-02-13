FROM rocker/shiny:4.1.2

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -qq libxml2

RUN rm -rf /srv/shiny-server/* /opt/shiny-server/samples/
WORKDIR /srv/shiny-server
COPY deps.R .
RUN Rscript deps.R
COPY app.R .
