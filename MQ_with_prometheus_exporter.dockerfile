# © Copyright IBM Corporation 2019
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM mqbase:1.0

ARG GOPATH_ARG="/go"
ARG GOVERSION=1.13.15

ENV GOVERSION=${GOVERSION}   \
    GOPATH=$GOPATH_ARG \
    GOTAR=go${GOVERSION}.linux-amd64.tar.gz \
    ORG="github.com/ibm-messaging"


# Install the Go compiler and Git
RUN export DEBIAN_FRONTEND=noninteractive \
  && bash -c 'source /etc/os-release; \
     echo "deb http://archive.ubuntu.com/ubuntu/ ${UBUNTU_CODENAME} main restricted" > /etc/apt/sources.list; \
     echo "deb http://archive.ubuntu.com/ubuntu/ ${UBUNTU_CODENAME}-updates main restricted" >> /etc/apt/sources.list; \
     echo "deb http://archive.ubuntu.com/ubuntu/ ${UBUNTU_CODENAME}-backports main restricted universe" >> /etc/apt/sources.list; \
     echo "deb http://archive.ubuntu.com/ubuntu/ ${UBUNTU_CODENAME} universe" >> /etc/apt/sources.list; \
     echo "deb http://archive.ubuntu.com/ubuntu/ ${UBUNTU_CODENAME}-updates universe" >> /etc/apt/sources.list;' \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
  && rm -rf /var/lib/apt/lists/*


# Create location for the git clone
RUN mkdir -p $GOPATH/src $GOPATH/bin $GOPATH/pkg \
  && chmod -R 777 $GOPATH \
  && mkdir -p $GOPATH/src/$ORG \
  && cd /tmp       \
  && wget -nv https://dl.google.com/go/${GOTAR} \
  && tar -xf ${GOTAR} \
  && mv go /usr/lib/go-${GOVERSION} \
  && rm -f ${GOTAR} 

# Insert the script that will do the build

RUN export CGO_LDFLAGS_ALLOW="-Wl,-rpath.*" \
  && export GOPATH=~/go \
  && export GOROOT=/usr/lib/golang  \
  && mkdir -p $GOPATH/src \
  && cd $GOPATH/src  \
  && git clone https://github.com/ibm-messaging/mq-metric-samples

WORKDIR $GOPATH/src/github.com/ibm-messaging/mq-metric-samples
RUN chmod 777 go.*

RUN chmod 777 config.common.yaml

#RUN /usr/lib/go-${GOVERSION}/bin/go mod download

# Copy the rest of the source tree from this directory into the container and
# make sure it's readable by the user running the container
RUN chmod -R a+rwx $GOPATH/src/github.com/ibm-messaging/mq-metric-samples \
 && cd $GOPATH/src/github.com/ibm-messaging/mq-metric-samples\
 && export CGO_LDFLAGS_ALLOW='-Wl,-rpath.*' \
 && go build -o $GOPATH/bin/mq_prometheus ./cmd/mq_prometheus/*.go    