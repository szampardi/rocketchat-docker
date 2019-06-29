FROM    debian:buster-slim

SHELL   ["/bin/bash", "-xeo", "pipefail", "-c"]

RUN     export DEBIAN_FRONTEND=noninteractive; \
        apt-get update; \
        apt-get dist-upgrade -y; \
        apt-get install -y --no-install-recommends \
                build-essential ca-certificates curl git jq make python-minimal python-dev python-pip procps; \
        rm -fr /tmp/* /root/.cache /var/lib/apt/*

RUN     useradd --create-home --system --shell "/sbin/nologin" rc

ARG     NODE_VERSION="v8.11.4"
ARG     OS="linux"
ARG     OS_ARCH="x64"
ENV     NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-${OS}-${OS_ARCH}.tar.gz"
RUN     mkdir -vp /usr/local/nodejs; \
        curl -fsSLo- "${NODE_URL}" | tar zxf - -C /usr/local/nodejs --strip-components 1; \
        for _bin in $(find /usr/local/nodejs/bin); do ln -sv "$_bin" "/usr/local/bin/$(basename $_bin)"; done; \
        node --version; \
	npm install -g node-pre-gyp yarn request; \
	for _bin in $(find /usr/local/nodejs/bin); do ln -sv "$_bin" "/usr/local/bin/$(basename $_bin)" || true; \
	done ; \
	npm cache clear --force

RUN     curl https://install.meteor.com/ | bash -xv

ARG     ROCKETCHAT_VERSION
RUN     mkdir -vp /usr/src/rocket.chat; \
        if [[ ! -z "${ROCKETCHAT_VERSION}" ]]; then \
                curl -fsSLo- "https://api.github.com/repos/RocketChat/Rocket.Chat/tarball/${ROCKETCHAT_VERSION}" | tar zxf - -C /usr/src/rocket.chat --strip-components 1; \
        else \
                _tarball_url="$(curl -sL https://api.github.com/repos/RocketChat/Rocket.Chat/releases/latest | jq -r '.tarball_url')"; \
                curl -fsSLo- "${_tarball_url}" | tar zxf - -C /usr/src/rocket.chat --strip-components 1; \
        fi; \
        chown -R rc:rc /usr/src/rocket.chat

USER    rc
WORKDIR /usr/src/rocket.chat

RUN	meteor npm install

RUN	meteor npm run postinstall

RUN	_modules=""; \
	for _node_module in $(jq -r '.devDependencies | keys[]' package.json); do _modules+=" ${_node_module}@$(jq -r ".devDependencies.\"${_node_module}\"" package.json | tr -d '^')"; done; \
	meteor npm install --save ${_modules}

RUN	meteor build --server-only --directory ~/bundle


FROM	debian:buster-slim

ENV	NODE_ENV="production"

SHELL	["/bin/bash", "-xeo", "pipefail", "-c"]

RUN	export DEBIAN_FRONTEND=noninteractive; \
	apt-get update; \
	apt-get dist-upgrade -y; \
	apt-get install -y --no-install-recommends \
		ca-certificates curl; \
	rm -fr /tmp/* /root/.cache /var/lib/apt/*

RUN	useradd --no-create-home --home /tmp --system --shell "/sbin/nologin" rocketchat; \
	mkdir -vp /app/uploads; \
	chown -vR rocketchat:rocketchat /app

ARG     NODE_VERSION="v8.11.4"
ARG     OS="linux"
ARG     OS_ARCH="x64"
ENV     NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-${OS}-${OS_ARCH}.tar.gz"
RUN	mkdir -vp /usr/local/nodejs; \
	curl -fsSLo- "${NODE_URL}" | tar zxf - -C /usr/local/nodejs --strip-components 1; \
	for _bin in $(find /usr/local/nodejs/bin); do ln -sv "$_bin" "/usr/local/bin/$(basename $_bin)"; done; \
	node --version; \
	for _bin in $(find /usr/local/nodejs/bin); do ln -sv "$_bin" "/usr/local/bin/$(basename $_bin)" || true; \
	done ; \
	npm cache clear --force

COPY	--from=0 --chown=rocketchat:rocketchat	/home/rc/bundle		/app/

RUN	cd /app/bundle/programs/server; \
	npm install; \
	npm cache clear --force; \
	chown -R rocketchat:rocketchat /app

USER	rocketchat

WORKDIR	/app/bundle

ENV	NODE_ENV=production \
	DEPLOY_METHOD=docker-official \
	MONGO_URL=mongodb://db:27017/rocketchat?replicaSet=rs01 \
        MONGO_OPLOG_URL=mongodb://db:27017/local?replicaSet=rs01 \
	HOME=/tmp \
	PORT=3000 \
	ROOT_URL=http://localhost:3000 \
	Accounts_AvatarStorePath=/app/uploads
#- ROOT_URL='http://chat.localhost:3000/'
#- MAIL_URL='smtp://user:password@mailhost:port/'

EXPOSE	3000
VOLUME	/app/uploads

ENTRYPOINT ["/bin/bash", "-c"]
CMD	["sleep 10; /usr/local/bin/node main.js"]
