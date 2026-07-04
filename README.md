# Sorvec Official Website

Static website for Sorvec, containerized with Docker and served by Caddy with automatic HTTPS.

## Domain

Production hostname:

- `sorvec.com.au`

Caddy obtains and renews the HTTPS certificate automatically after DNS points to the server and ports `80` and `443` are reachable.

## Files

- `Dockerfile` builds the static site into a Caddy container.
- `Caddyfile` configures HTTPS, static file serving, compression, and security headers.
- `deploy.sh` builds the image if `latest` is missing, replaces any existing running container, and starts the site.

## EC2 Prerequisites

1. Launch an EC2 instance, for example Amazon Linux 2023 or Ubuntu.
2. Attach an Elastic IP so the public IP remains stable.
3. Open inbound security group rules:
   - TCP `22` from your IP for SSH.
   - TCP `80` from `0.0.0.0/0` and `::/0`.
   - TCP `443` from `0.0.0.0/0` and `::/0`.
4. Install Docker on the instance.

Amazon Linux 2023:

```sh
sudo dnf update -y
sudo dnf install -y docker git
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
```

Ubuntu:

```sh
sudo apt-get update
sudo apt-get install -y docker.io git
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
```

Log out and back in after adding your user to the `docker` group.

## DNS On AWS

In Route 53, create or update the hosted zone for `sorvec.com.au`.

Create an `A` record:

- Name: `sorvec.com.au`
- Type: `A`
- Value: your EC2 Elastic IP
- TTL: `300`

If your DNS is hosted outside Route 53, create the same `A` record with that DNS provider.

## Deploy On EC2

Clone the repository:

```sh
git clone https://github.com/XiuyuanLu/sorvec-official-web.git
cd sorvec-official-web
```

Deploy:

```sh
./deploy.sh
```

Force a rebuild after changing site files:

```sh
./deploy.sh --rebuild
```

Check the running container:

```sh
docker ps --filter name=sorvec-official-web
docker logs sorvec-official-web
```

## Local Docker Test

Build the image:

```sh
docker build -t sorvec-official-web:latest .
```

Run it locally on alternate ports:

```sh
HOST_HTTP_PORT=8080 HOST_HTTPS_PORT=8443 ./deploy.sh
```

Then open `http://localhost:8080`. Local HTTPS will not match `sorvec.com.au`; production HTTPS is issued on EC2 after DNS is live.

## Troubleshooting HTTPS

- Confirm `sorvec.com.au` resolves to the EC2 Elastic IP.
- Confirm ports `80` and `443` are open in the EC2 security group.
- Confirm no other process is using ports `80` or `443` on the instance.
- Check Caddy logs with `docker logs sorvec-official-web`.
- Keep the Docker volumes created by `deploy.sh`; they store Caddy certificate data under the named volume `sorvec-official-web-caddy-data`.
