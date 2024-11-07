#!/usr/bin/env bash

set -xve

NODEJS_VERSION="${NODEJS_VERSION:-20.17.0}"
ROCKETCHAT_VERSION=${ROCKETCHAT_VERSION:-$(curl -sL "https://api.github.com/repos/RocketChat/Rocket.Chat/releases/latest" | jq -r '.name')}
_DOCKER_IMAGE="${_DOCKER_IMAGE:-nexus166/rocketchat}"

if ! docker manifest inspect "${_DOCKER_IMAGE}:${ROCKETCHAT_VERSION}-bundle" || [[ ${FORCE_BUILD} == "true" ]]; then
	docker build --rm --progress=plain --push \
		--build-arg NODEJS_VERSION="${NODEJS_VERSION}" \
		--build-arg "ROCKETCHAT_VERSION=${ROCKETCHAT_VERSION}" \
		--tag "${_DOCKER_IMAGE}:${ROCKETCHAT_VERSION}-bundle" -f bundle.Dockerfile .
	#docker push "${_DOCKER_IMAGE}:${ROCKETCHAT_VERSION}-bundle"
fi

if ! docker manifest inspect "${_DOCKER_IMAGE}:${ROCKETCHAT_VERSION}" || [[ ${FORCE_BUILD} == "true" ]]; then
	docker buildx build --rm --progress=plain --push \
		--platform ${DOCKER_PLATFORMS:-"linux/amd64"} \
		--build-arg NODEJS_VERSION="${NODEJS_VERSION}" \
		--build-arg "ROCKETCHAT_VERSION=${ROCKETCHAT_VERSION}" \
		--tag "${_DOCKER_IMAGE}:${ROCKETCHAT_VERSION}" -f Dockerfile .
fi
