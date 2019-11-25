#!/bin/sh
set -o errexit

# create registry container unless it already exists 
CLUSTER_NAME="my-cluster"                   # the desired cluster name
KIND_VERSION="kindest/node:v1.16.3"         # use a controlled way of K8s in kind
REGISTRY_CONTAINER_NAME='kind-registry'     # the desired registry container name
REGISTRY_PORT='5000'                        # the desired registry container port

if [ "$(docker inspect -f '{{.State.Running}}' "${REGISTRY_CONTAINER_NAME}")" != 'true' ]; then
  docker run -d -p "${REGISTRY_PORT}:5000" --restart=always --name "${REGISTRY_CONTAINER_NAME}" registry:2
fi

# create a cluster with the local registry enabled in containerd
cat kind-config-basic.yaml - <<EOF | kind create cluster --name ${CLUSTER_NAME} --image ${KIND_VERSION} --config=-
containerdConfigPatches: 
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry:${REGISTRY_PORT}"]
    endpoint = ["http://registry:${REGISTRY_PORT}"]
EOF

# add the registry to /etc/hosts on each node
for node in $(kind get nodes --name ${CLUSTER_NAME}); do
  docker exec "${node}" sh -c \
    "echo $(docker inspect --format '{{.NetworkSettings.IPAddress}}' "${REGISTRY_CONTAINER_NAME}") registry >> /etc/hosts"
done