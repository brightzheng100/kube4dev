#!/bin/sh
set -o errexit

# the desired cluster name
KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-my-cluster}"
# use a controlled way of K8s in kind, e.g. KIND_CLUSTER_VERSION=kindest/node:v1.16.3
KIND_CLUSTER_VERSION="${KIND_CLUSTER_VERSION:-kindest/node:latest}"
# the desired registry container name
REGISTRY_CONTAINER_NAME="${REGISTRY_CONTAINER_NAME:-kind-registry}"
# the desired registry container port
REGISTRY_CONTAINER_PORT="${REGISTRY_CONTAINER_PORT:-5000}"

# create a docker container as the Docker Registry
if [ "$(docker inspect -f '{{.State.Running}}' "${REGISTRY_CONTAINER_NAME}")" != 'true' ]; then
  docker run -d -p "${REGISTRY_CONTAINER_PORT}:5000" --restart=always --name "${REGISTRY_CONTAINER_NAME}" registry:2
fi

# create a cluster with the local registry enabled in containerd
cat kind-config-basic.yaml - <<EOF | kind create cluster --name ${KIND_CLUSTER_NAME} --image ${KIND_CLUSTER_VERSION} --config=-
containerdConfigPatches: 
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry:${REGISTRY_CONTAINER_PORT}"]
    endpoint = ["http://registry:${REGISTRY_CONTAINER_PORT}"]
EOF

# add the registry to /etc/hosts on each node
for node in $(kind get nodes --name ${KIND_CLUSTER_NAME}); do
  docker exec "${node}" sh -c \
    "echo $(docker inspect --format '{{.NetworkSettings.IPAddress}}' "${REGISTRY_CONTAINER_NAME}") registry >> /etc/hosts"
done