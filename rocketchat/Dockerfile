FROM    debian:bullseye-slim
SHELL   ["/bin/bash", "-xeo", "pipefail", "-c"]

RUN     export DEBIAN_FRONTEND=noninteractive; \
        apt-get update; \
        apt-get dist-upgrade -y; \
        apt-get install -y build-essential ca-certificates curl g++ git jq libkrb5-dev make pkg-config python2-minimal python2-dev procps; \
        rm -fr /tmp/* /root/.cache /var/lib/apt/*; \
        useradd --create-home --system --shell "/sbin/nologin" rc

ARG     ROCKETCHAT_VERSION
RUN     mkdir -vp /usr/src/rocket.chat; \
        if [[ ! -z "${ROCKETCHAT_VERSION}" ]]; then \
                curl -fsSLo- "https://api.github.com/repos/RocketChat/Rocket.Chat/tarball/${ROCKETCHAT_VERSION}" | tar zxf - -C /usr/src/rocket.chat --strip-components 1; \
        else \
                curl -fsSLo- "$(curl -sL https://api.github.com/repos/RocketChat/Rocket.Chat/releases/latest | jq -r '.tarball_url')" | \
                        tar zxf - -C /usr/src/rocket.chat --strip-components 1; \
        fi; \
        chown -R rc:rc /usr/src/rocket.chat; \
        curl https://install.meteor.com/ | bash -x; \
        printf '#!/bin/sh\nmeteor node ${@}\n' > /usr/bin/fakenode; \
        chmod +x /usr/bin/fakenode; \
        ln -vs /usr/bin/fakenode /usr/local/bin/node; \
        ln -vs /usr/bin/fakenode /usr/local/bin/nodejs

USER    rc
WORKDIR /usr/src/rocket.chat

RUN     meteor npm install; \
        meteor npm run postinstall; \
        _modules=""; \
        for _node_module in $(jq -r '.devDependencies | keys[]' package.json); do _modules+=" ${_node_module}@$(jq -r ".devDependencies.\"${_node_module}\"" package.json | tr -d '^')"; done; \
        meteor npm install --save ${_modules}; \
        meteor build --server-only --directory ~/bundle

FROM    debian:bullseye-slim

ENV     NODE_ENV="production"

SHELL   ["/bin/bash", "-xeo", "pipefail", "-c"]

RUN     export DEBIAN_FRONTEND=noninteractive; \
        apt-get update; \
        apt-get dist-upgrade -y; \
        apt-get install -y --no-install-recommends \
                ca-certificates curl nodejs npm; \
        rm -fr /tmp/* /root/.cache /var/lib/apt/*; \
        useradd --no-create-home --home /tmp --system --shell "/sbin/nologin" rocketchat; \
        mkdir -vp /app/uploads; \
        chown -vR rocketchat:rocketchat /app; \
        node --version; \
        npm cache clear --force

COPY    --from=0 --chown=rocketchat:rocketchat  /home/rc/bundle         /app/

RUN     cd /app/bundle/programs/server; \
        npm install; \
        npm cache clear --force; \
        chown -R rocketchat:rocketchat /app

USER    rocketchat

WORKDIR /app/bundle

ENV     NODE_ENV=production \
        DEPLOY_METHOD=docker-official \
        MONGO_URL=mongodb://db:27017/rocketchat?replicaSet=rs01 \
        MONGO_OPLOG_URL=mongodb://db:27017/local?replicaSet=rs01 \
        HOME=/tmp \
        PORT=3000 \
        ROOT_URL=http://localhost:3000 \
        Accounts_AvatarStorePath=/app/uploads
#- ROOT_URL='http://chat.localhost:3000/'
#- MAIL_URL='smtp://user:password@mailhost:port/'

EXPOSE  3000
VOLUME  /app/uploads

ENTRYPOINT ["/bin/bash", "-xc"]
CMD     ["sleep 10; nodejs main.js"]
