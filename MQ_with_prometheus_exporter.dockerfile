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
  && apt-get install -y ca-certificates \
  curl \
  && rm -rf /var/lib/apt/lists/*


# Create location for the git clone
RUN mkdir -p $GOPATH/src $GOPATH/bin $GOPATH/pkg $GOPATH/src/github.com/ibm-messaging \
  && chmod -R 777 $GOPATH \
  && cd /tmp       \
  && wget -nv https://golang.org/dl/${GOTAR} --no-check-certificate \
  && tar -xf go1.13.15.linux-amd64.tar.gz \
  && mv go /usr/lib/go-${GOVERSION} \
  && rm -f go1.13.15.linux-amd64.tar.gz 

# Location of the downloadable MQ client package \
ENV RDURL="https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqdev/redist" \
    RDTAR="IBM-MQC-Redist-LinuxX64.tar.gz" \
    VRMF=9.2.1.0

# Install the MQ client from the Redistributable package. This also contains the
# header files we need to compile against. Setup the subset of the package
# we are going to keep - the genmqpkg.sh script removes unneeded parts
ENV genmqpkg_incnls=1 \
    genmqpkg_incsdk=1 \
    genmqpkg_inctls=1

RUN cd /opt/mqm \
 && curl -LO "$RDURL/$VRMF-$RDTAR" \
 && tar -zxf ./*.tar.gz \
 && rm -f ./*.tar.gz \
 && bin/genmqpkg.sh -b /opt/mqm


# Insert the script that will do the build

RUN export CGO_LDFLAGS_ALLOW="-Wl,-rpath.*" \
  && export GOPATH=/go \
  && export GOROOT=/usr/lib/golang  \
  && mkdir -p ${GOPATH}/src/github.com/ibm-messaging \
  && cd $GOPATH/src/github.com/ibm-messaging  \
  && git clone https://github.com/ibm-messaging/mq-metric-samples

WORKDIR ${GOPATH}/src/github.com/ibm-messaging/mq-metric-samples
#RUN cd ${GOPATH}/src/github.com/ibm-messaging/mq-metric-samples 
RUN chmod 777 go.*
RUN chmod 777 config.common.yaml

#RUN /usr/lib/go-${GOVERSION}/bin/go mod download

# Copy the rest of the source tree from this directory into the container and
# make sure it's readable by the user running the container
RUN chmod -R a+rwx $GOPATH/src/github.com/ibm-messaging/mq-metric-samples \
 && cd $GOPATH/src/github.com/ibm-messaging/mq-metric-samples \
 && export CGO_LDFLAGS_ALLOW='-Wl,-rpath.*' \
 && export PATH=$PATH:/usr/lib/go-${GOVERSION}/bin:/go/bin \
 && go build -mod=vendor -o $GOPATH/bin/mq_prometheus $GOPATH/src/github.com/ibm-messaging/mq-metric-samples/cmd/mq_prometheus/*.go    