# © Copyright IBM Corporation 2015, 2017

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


FROM mqprometheus:1.0

LABEL maintainer "Arthur Barr <arthur.barr@uk.ibm.com>, Rob Parker <PARROBE@uk.ibm.com>"

LABEL "ProductID"="98102d16795c4263ad9ca075190a2d4d" \
      "ProductName"="IBM MQ Advanced for Developers" \
      "ProductVersion"="9.0.4"

COPY *.sh /usr/local/bin/

COPY *.mqsc /etc/mqm/

COPY admin.json /etc/mqm/

COPY mq-dev-config /etc/mqm/mq-dev-config
RUN chmod +x /usr/local/bin/*.sh

# Always use port 1414 (the Docker administrator can re-map ports at runtime)
# Expose port 9443 for the web console

EXPOSE 1414 9443 9157

ENV LANG=en_US.UTF-8
ENTRYPOINT ["mq.sh"]