# Appendix B - Koha on Docker

This folder contains a Dockerfile, some additional files and scripts for running Koha.
The files were based on https://gitlab.com/koha-community/docker/koha-docker, however 
I have removed some unnecessary files and modified the scripts to support Koha 21.11.

Currently, there is an option to use an external Memcached server or run one inside 
the container.

A RabbitMQ server for Koha is also created inside the container.

Check out ```config-main.env``` for the main configuration options and 
```config-sip.env``` for SIP specific configuration options.

The OPAC is exposed on port 8080 and the staff interface on port 8081.

Example usage:
```
sudo podman build -t koha .
sudo podman run --env-file=config-main.env --cap-add=SYS_NICE --cap-add=DAC_READ_SEARCH -p 18080:8080 -p 18081:8081 koha
```
