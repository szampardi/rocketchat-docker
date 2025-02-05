ARG	NODEJS_VERSION
ARG	ROCKETCHAT_VERSION
ARG	DOCKER_IMAGE=docker.io/nexus166/rocketchat
FROM	${DOCKER_IMAGE}:${ROCKETCHAT_VERSION}-bundle as bundle
FROM	node:${NODEJS_VERSION}-bookworm-slim
COPY	--from=bundle /etc/passwd /etc/group /etc/
COPY	--from=bundle /app/bundle     /app/bundle

ENV	NODE_ENV="production"
SHELL	["/bin/bash", "-xeo", "pipefail", "-c"]
RUN	export DEBIAN_FRONTEND=noninteractive; \
	apt-get update; \
	apt-get dist-upgrade -y; \
	apt-get install -y --no-install-recommends build-essential ca-certificates curl make python3-dev unzip; \
	rm -fr /tmp/* /root/.cache /var/lib/apt/*; \
	node --version; \
	mkdir -vp /home/rocketchat /app/{.npm,uploads}; \
	chown -R rocketchat:rocketchat /home/rocketchat /app/bundle

ARG     DENO_VERSION=1.37.1
RUN     case $(dpkg --print-architecture) in \
                amd64) _deno_dl="https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/deno-x86_64-unknown-linux-gnu.zip" ;; \
                *) _deno_dl="https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/deno-aarch64-unknown-linux-gnu.zip" ;; \
        esac; \
        cd $(mktemp -d); \
        curl -fsSLo deno.zip "${_deno_dl}"; \
        unzip deno.zip; \
        mv deno /usr/local/bin/deno; \
        rm -rfv $(pwd)

WORKDIR	/app/bundle
#USER	rocketchat
RUN	cd programs/server; \
	npm install --omit=dev --unsafe-perm; \
	cd npm/node_modules/isolated-vm; \
	npm install; \
	npm cache clear --force

#USER	root
RUN	apt-get remove --purge --autoremove -y build-essential gcc g++ make python3; \
	apt-get clean; \
	apt-get autoclean; \
	chown -R rocketchat:rocketchat /app/bundle

USER	rocketchat
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

ENTRYPOINT ["/bin/bash", "-xc"]
CMD	["sleep 10; nodejs main.js"]
