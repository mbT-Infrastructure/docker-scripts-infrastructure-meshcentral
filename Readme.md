# scripts-infrastructure Meshcentral image

This Container image extends the
[meshcentral image](https://github.com/mbT-Infrastructure/docker-meshcentral).
Make sure to also configure environment variables, ports and volumes from that image.

This image contains the infrastructure scripts and
the components to execute them on devices connected to Meshcentral.

## Environment variables

- `SERVER_PASSWORD`
    - Password to use for the Meshcentral connection.
- `SERVER_URL`
    - Url of the Meshcentral server.
- `SERVER_USERNAME`
    - Username to use for the Meshcentral connection.


## Volumes

- `/media/workdir`
    - The working directory of the scripts. Use it to mount configuration files.


## Development

To build and run for development run:
```bash
docker compose --file docker-compose-dev.yaml up --build
```

To build the image locally run:
```bash
./docker-build.sh
```
