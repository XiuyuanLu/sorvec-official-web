FROM caddy:2-alpine

WORKDIR /srv

COPY Caddyfile /etc/caddy/Caddyfile
COPY index.html privacy.html terms.html styles.css ./
COPY Assets ./Assets
