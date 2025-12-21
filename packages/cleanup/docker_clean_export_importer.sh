#!/usr/bin/env bash
set -ex

IMAGE_NAME=${1}

if [ -z "$IMAGE_NAME" ]; then
  echo "Usage: $0 <image-name>"
  exit 1
fi
CLEAN_IMAGE_NAME=${IMAGE_NAME}-cleanup
# Get jetson-containers data path
PWD="$(pwd)"

DOCKER_BUILDKIT=0 docker build --network=host \
  --tag ${CLEAN_IMAGE_NAME} \
  --file ${PWD}/Dockerfile \
  --build-arg BASE_IMAGE=${IMAGE_NAME} \
   ${PWD}

CONTAINER_ID="tmp_clean"

SYSTEM_ARCH=tegra-aarch64 \
docker run -d --runtime nvidia --env NVIDIA_DRIVER_CAPABILITIES=all --name ${CONTAINER_ID} ${CLEAN_IMAGE_NAME}

docker export ${CONTAINER_ID} > ${CONTAINER_ID}.tar

declare -a flags
while IFS='=' read -r key value; do
  flags+=(-c "ENV $key=\"$value\"")
done < <(docker inspect "$CONTAINER_ID" --format='{{range .Config.Env}}{{println .}}{{end}}' | grep '=.')

EXPORTED_IMAGE_NAME=${IMAGE_NAME}-exported
docker import "${flags[@]}" -c 'CMD ["/bin/bash"]' ${CONTAINER_ID}.tar "$EXPORTED_IMAGE_NAME"

rm ${CONTAINER_ID}.tar
docker rm -f ${CONTAINER_ID}
docker image rm ${CLEAN_IMAGE_NAME}

echo ${EXPORTED_IMAGE_NAME}

