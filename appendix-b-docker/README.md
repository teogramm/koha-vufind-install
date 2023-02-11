# Appendix B - Koha on Docker

*Notice: SIP and Z3950 are not functional for now.*

This folder contains a Dockerfile, some additional files and scripts for running Koha.
The files were based on https://gitlab.com/koha-community/docker/koha-docker, however they have been extensively rewrittend to support s6.

A separate RabbitMQ server with the stomp plugin is required as well as a Memcached server.
Both can be easily created using the images available on Dockrt Hub.

Check out ```config-main.env``` for the main configuration options and 
```config-sip.env``` for SIP specific configuration options.

The OPAC is exposed on port 8080 and the staff interface on port 8081.

Example usage:
```
sudo podman build -t koha .
sudo podman run --env-file=config-main.env --cap-add=SYS_NICE --cap-add=DAC_READ_SEARCH -p 18080:8080 -p 18081:8081 koha
```
