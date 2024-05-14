ARG	NODEJS_VERSION=fermium
FROM    node:${NODEJS_VERSION}-bullseye-slim AS bundle
USER	root
SHELL   ["/bin/bash", "-xeo", "pipefail", "-c"]

RUN     export DEBIAN_FRONTEND=noninteractive; \
        apt-get update; \
        apt-get dist-upgrade -y; \
        apt-get install -y build-essential ca-certificates curl g++ git jq libkrb5-dev make pkg-config python3-minimal python3-dev procps; \
	npm install --force -g yarn; \
        rm -fr /tmp/* /root/.cache /var/lib/apt/*; \
	useradd --create-home --system --shell "/sbin/nologin" rocketchat; \
	mkdir -vp /app/bundle /usr/src/rocket.chat; \
	chown -vR rocketchat:rocketchat /app /usr/src/rocket.chat

USER	rocketchat
WORKDIR	/usr/src/rocket.chat
ARG	ROCKETCHAT_VERSION
ARG	ROCKETCHAT_VCS="https://github.com/RocketChat/Rocket.Chat"
RUN	if [[ -n "${ROCKETCHAT_VERSION}" ]]; then \
		git clone --single-branch --branch="${ROCKETCHAT_VERSION}" --depth=1 "${ROCKETCHAT_VCS}" /usr/src/rocket.chat; \
	else \
		git clone --single-branch --branch="$(curl -sL https://api.github.com/repos/RocketChat/Rocket.Chat/releases/latest | jq -r '.tag_name')" --depth=1 "${ROCKETCHAT_VCS}"  /usr/src/rocket.chat; \
	fi

#YARN_CHECKSUM_BEHAVIOR=ignore
USER	rocketchat
RUN	curl "https://install.meteor.com/?release=$(cut -d '@' -f2 <apps/meteor/.meteor/release)" | bash -x; \
	export PATH="${HOME}/.meteor:${PATH}"; \
	yarn; \
	yarn lint; \
	yarn turbo run translation-check; \
	yarn turbo run typecheck; \
	yarn build:ci

RUN	ls /tmp/dist
FROM	scratch
COPY	--from=bundle /etc/passwd /etc/group	/etc/
COPY	--from=bundle /tmp/dist /app/
