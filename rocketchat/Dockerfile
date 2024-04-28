ARG	NODEJS_VERSION
ARG	ROCKETCHAT_VERSION
ARG	DOCKER_IMAGE=docker.io/nexus166/rocketchat
FROM	${DOCKER_IMAGE}:${ROCKETCHAT_VERSION}-bundle as bundle
FROM	node:${NODEJS_VERSION}-bullseye-slim
COPY	--from=bundle /etc/passwd /etc/group /etc/
COPY	--from=bundle /app/bundle     /app/bundle

ENV	NODE_ENV="production"
SHELL	["/bin/bash", "-xeo", "pipefail", "-c"]
RUN	export DEBIAN_FRONTEND=noninteractive; \
	apt-get update; \
	apt-get dist-upgrade -y; \
	apt-get install -y --no-install-recommends automake cmake autoconf build-essential ca-certificates curl gcc g++ libtool make python3; \
	rm -fr /tmp/* /root/.cache /var/lib/apt/*; \
	node --version; \
	mkdir -vp /home/rocketchat /app/{.npm,uploads}; \
	chown -R rocketchat:rocketchat /app /home/rocketchat

WORKDIR	/app/bundle
USER	rocketchat
RUN	curl https://sh.rustup.rs -sSfo /tmp/rustup.sh; \
	chmod +x /tmp/rustup.sh; \
	/tmp/rustup.sh -y
RUN	export PATH=~/.cargo/bin:"${PATH}"; \
	cd programs/server; \
	ls -lhtra; \
	rm -vfr npm/node_modules/sharp/vendor; \
	yarn; \
	npm cache clean --force; \
	rm -fr ~/.cargo/bin

USER	root
RUN	apt-get remove --purge --autoremove -y build-essential gcc g++ make python3

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
