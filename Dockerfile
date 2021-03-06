# The MIT License
#
#  Copyright (c) 2015, CloudBees, Inc.
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.

FROM openjdk:8-jdk-alpine
MAINTAINER Elric Milon

ENV HOME /home/jenkins
RUN addgroup -S -g 10000 jenkins

RUN adduser -S -u 10000 -h $HOME -G jenkins jenkins
LABEL Description="This is a base image, which provides the Jenkins agent executable (slave.jar)" Vendor="Jenkins project" Version="3.10"
ARG VERSION=3.10
ARG AGENT_WORKDIR=/home/jenkins/agent
RUN apk add --update --no-cache curl bash git openssh-client openssl \
  && curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar \
  && apk del curl
USER jenkins ENV AGENT_WORKDIR=${AGENT_WORKDIR} RUN mkdir /home/jenkins/.jenkins && mkdir -p ${AGENT_WORKDIR}
VOLUME /home/jenkins/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR /home/jenkins


COPY jenkins-slave /usr/local/bin/jenkins-slave

ENTRYPOINT ["jenkins-slave"]

# Root user is required to interact with Docker via docker.sock
USER root

RUN apk add --no-cache \
		ca-certificates

ENV DOCKER_CHANNEL stable
ENV DOCKER_VERSION 17.06.0-ce

RUN set -ex; \
	apk add --no-cache --virtual .fetch-deps \
		tar \
	; \
	\
# this "case" statement is generated via "update.sh"
	apkArch="$(apk --print-arch)"; \
	case "$apkArch" in \
		x86_64) dockerArch='x86_64' ;; \
		s390x) dockerArch='s390x' ;; \
		*) echo >&2 "error: unsupported architecture ($apkArch)"; exit 1 ;;\
	esac; \
	\
	wget "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/${dockerArch}/docker-${DOCKER_VERSION}.tgz" -O- | \
	tar --extract \
		--strip-components 1 \
		--directory /usr/local/bin/ \
        -z \
        --file - \
	; \
	\
	apk del .fetch-deps; \
	\
	dockerd -v; \
	docker -v

RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.4/community' >> /etc/apk/repositories \
  && apk --update add make \
  bash \
  iptables \
  e2fsprogs \
  python \
  py-pip \
  py-setuptools \
  ca-certificates \
  groff \
  less && \
  pip --no-cache-dir install awscli && \
  rm -rf /var/cache/apk/*
