ARG	NODEJS_VERSION
ARG	ROCKETCHAT_VERSION
ARG	DOCKER_IMAGE=docker.io/nexus166/rocketchat
FROM	${DOCKER_IMAGE}:${ROCKETCHAT_VERSION}-bundle as bundle
FROM	node:${NODEJS_VERSION}-bullseye
COPY	--from=bundle /etc/passwd /etc/group /etc/
COPY	--from=bundle --chown=rocketchat:rocketchat /app/bundle     /app/bundle

ENV	NODE_ENV="production"
SHELL	["/bin/bash", "-xeo", "pipefail", "-c"]
RUN	export DEBIAN_FRONTEND=noninteractive; \
	apt-get update; \
	apt-get dist-upgrade -y; \
	apt-get install -y --no-install-recommends ca-certificates; \
	rm -fr /tmp/* /root/.cache /var/lib/apt/*; \
	node --version; \
	mkdir -vp /home/rocketchat /app/{.npm,uploads}; \
	chown -R rocketchat:rocketchat /home/rocketchat

WORKDIR	/app/bundle
USER	rocketchat
RUN	cd programs/server; \
	npm install --production; \
	rm -rf npm/node_modules/sharp; \
	npm install sharp@0.32.6; \
	mv node_modules/sharp npm/node_modules/sharp; \
	rm -rf npm/node_modules/isolated-vm; \
	npm install isolated-vm@4.4.2; \
	mv node_modules/isolated-vm npm/node_modules/isolated-vm; \
	cd npm; \
	npm rebuild bcrypt --build-from-source; \
	npm cache clear --force

USER	root
RUN	apt-get remove --purge --autoremove -y build-essential gcc g++ make python3; \
	apt-get clean; \
	apt-get autoclean

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
