FROM jenkins/jnlp-slave:alpine as jnlp

FROM alpine:latest AS dockercli

ARG DOCKER_VERSION=19.03.5

RUN wget -O docker.tgz https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION.tgz && \
    tar -xvzf docker.tgz && \
    chmod +x docker/docker

FROM maven:3.6.3-jdk-8

RUN apt-get update && \
    apt-get install -y \
        git \
        libfontconfig1 \
        libfreetype6

COPY --from=jnlp /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-agent
COPY --from=jnlp /usr/share/jenkins/agent.jar /usr/share/jenkins/agent.jar
COPY --from=dockercli docker/docker /usr/local/bin/docker
USER root

ENTRYPOINT ["/usr/local/bin/jenkins-agent"]