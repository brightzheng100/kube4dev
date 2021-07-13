
# kind - Kubernetes in Docker

As per the docs [here](https://kind.sigs.k8s.io/):
`kind` is a tool for running local Kubernetes clusters using Docker container "nodes".
`kind` was primarily designed for testing Kubernetes itself, but may be used for local development or CI.

So it's the "official" Kubernetes testing tool, and happens to be quite handy for Kubernetes developers/users too.

Compared to `k3s` cluster powered by `k3d`, as detailed [here](README-K3D-K3S.md), `kind`'s cluster is heavier but the binaries are 100% built from official repo.

## Prerequisites

- Docker (Desktop) is installed


## Install kind

```sh
# export the desired version
$ export KIND_VERSION=v0.11.1
$ curl -Lo ./kind "https://github.com/kubernetes-sigs/kind/releases/download/$KIND_VERSION/kind-$(uname)-amd64"
$ chmod +x ./kind && sudo mv ./kind /usr/local/bin/
```

Let's verify:

```sh
$ kind version
kind v0.11.1 go1.16.4 darwin/amd64
```


## Provision Kubernetes Cluster

The simple goal is to provision a Kubernetes cluster with **1 Master** + **3 Workers**

```sh
$ git clone https://github.com/brightzheng100/kube4dev.git && cd kube4dev
$ kind create cluster --name my-cluster --config kind/kind-config-basic.yaml
```

> Note:
> 1. You may specify `--image kindest/node:<VERSION>` to provision designated/desired version of Kubernetes, instead of `latest` by default, which is subject to change from time to time;
> 2. Above process will quickly provision a Kubernetes cluster with below components:
>     - 1 x Master "node"
>     - 3 x Worker "nodes"
> 3. See **[`Advanced Topics`](#advanced-topics)** for how to enable some interesting features


## Verify

```sh
$ kubectl config get-contexts
CURRENT   NAME              CLUSTER           AUTHINFO          NAMESPACE
*         kind-my-cluster   kind-my-cluster   kind-my-cluster

$ kubectl get nodes
NAME                       STATUS   ROLES                  AGE   VERSION
my-cluster-control-plane   Ready    control-plane,master   36s   v1.21.1
my-cluster-worker          Ready    <none>                 15s   v1.21.1
my-cluster-worker2         Ready    <none>                 15s   v1.21.1
my-cluster-worker3         Ready    <none>                 15s   v1.21.1

$ kubectl get ns
NAME                 STATUS   AGE
default              Active   73s
kube-node-lease      Active   75s
kube-public          Active   75s
kube-system          Active   75s
local-path-storage   Active   69s

$ kubectl create deployment nginx --image=nginx
deployment.apps/nginx created

$ kubectl get deploy,pod
NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
deployment.extensions/nginx   1/1     1            1           22s

NAME                         READY   STATUS    RESTARTS   AGE
pod/nginx-554b9c67f9-mxdjx   1/1     Running   0          21s
```

## Clean Up

```sh
$ kind delete cluster --name my-cluster
```


## Advanced Topics

`kind` offers almost all possible flexibility a Kubernetes cluster has.

You may consider some scenarios like:
- [Diving into Nodes](#diving-into-nodes) to see the components provisioned
- [Use desired CNI](#use-desired-cni), like `calico`, or `weave-net`, instead of the default `kindnet`
- [Enable NodePort support](#enable-nodeport-support)
- [Enable Ingress support](#enable-ingress-support), e.g. by `traefik` with exposed `NodePort`s
- [Enable metrics](#enable-metrics), e.g. by `metrics-server`
- [Enable Instant Monitoring](#enable-instant-monitoring), e.g. by tools like `kube-ops-view`
- [Enable Kubernetes Dashboard](#enable-kubernetes-dashboard)
- [Enable Routing to Services](#enable_routing_to_services)
- [Enable Loadbalancer support by MetalLB](#enable_loadbalancer_support_by_metallb)
- [Enable non-GA features](#enable-non-ga-features)
- [Spin up local Docker Registry](#spin-up-local-docker-registry) along with `kind create cluster`
- Maybe more

### Diving Into Nodes

Basically, each node is a Docker container, so accessing nodes is by `docker exec` command:

```sh
$ kind get nodes --name my-cluster
my-cluster-control-plane
my-cluster-worker3
my-cluster-worker2
my-cluster-worker

$ docker ps
CONTAINER ID   IMAGE                  COMMAND                  CREATED         STATUS         PORTS                       NAMES
8c1ae11ba5bb   kindest/node:v1.19.1   "/usr/local/bin/entr…"   3 minutes ago   Up 2 minutes                               my-cluster-worker3
35ae323d09f1   kindest/node:v1.19.1   "/usr/local/bin/entr…"   3 minutes ago   Up 2 minutes                               my-cluster-worker
745fe40e6639   kindest/node:v1.19.1   "/usr/local/bin/entr…"   3 minutes ago   Up 2 minutes   127.0.0.1:60091->6443/tcp   my-cluster-control-plane
ecb40f33f3d3   kindest/node:v1.19.1   "/usr/local/bin/entr…"   3 minutes ago   Up 2 minutes                               my-cluster-worker2

$ docker exec -it my-cluster-control-plane bash
root@my-cluster-control-plane:/# hostname
my-cluster-control-plane
root@my-cluster-control-plane:/# ls /etc/kubernetes/manifests/
etcd.yaml  kube-apiserver.yaml  kube-controller-manager.yaml  kube-scheduler.yaml
root@my-cluster-control-plane:/# systemctl status kubelet.service
● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/etc/systemd/system/kubelet.service; enabled; vendor preset: enabled)
    Drop-In: /etc/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: active (running) (thawing) since Tue 2020-12-22 10:11:48 UTC; 2min 56s ago
       Docs: http://kubernetes.io/docs/
   Main PID: 687 (kubelet)
      Tasks: 18 (limit: 6977)
     Memory: 46.7M
   ...
```

> Note:
> 1. Frankly, after `docker exec` into the "node", you really can't differentiate whether you're in a real VM or a Docker container -- the components are exactly the same as what I have provisioned by using `kubeadm` on VMs;
> 2. You may check out [this repo](https://github.com/brightzheng100/kubernetes-the-kubeadm-way) to see how to provision a **real and fully-fledged** `kubeadm`-based cluster on GCP.

### Use Desired CNI

You may use other CNI like `Calico`, or `WeaveNet` instead of the default `kindnet`.

Firstly, we need to disable CNI by adding below section in the kind config file:

```yaml
kind: Cluster
apiVersion: kind.sigs.k8s.io/v1alpha3
...
networking:
  disableDefaultCNI: true     # disable kindnet
  #podSubnet: 192.168.0.0/16  # set to Calico's default subnet
  podSubnet: 10.32.0.0/12     # set to WeaveNet's default subnet
```

> Note: do check out your desired CNI to learn what `podSubnet` might be preferred / required to set

I already provide a [`kind-config-advanced.yaml`](kind/kind-config-advanced.yaml) which would help you provision a highly customized Kubernetes cluster with default CNI disabled.

To provision such a cluster, do this:

```sh
$ kind create cluster --name my-cluster --config kind/kind-config-advanced.yaml
```

Lastly, you can create your desired overlay network.
Let's take `WeaveNet` as an example:

```sh
$ kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
serviceaccount/weave-net created
clusterrole.rbac.authorization.k8s.io/weave-net created
clusterrolebinding.rbac.authorization.k8s.io/weave-net created
role.rbac.authorization.k8s.io/weave-net created
rolebinding.rbac.authorization.k8s.io/weave-net created
daemonset.apps/weave-net created
```

Done!

### Enable NodePort Support

By default, the Docker container-based nodes expose only one port for Kubernetes API only.
To have `NodePort` support, we need to expose extra ports:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
...
- role: control-plane
  # this is to expose extra ports for NodePort
  # see #https://github.com/kubernetes-sigs/kind/pull/637, https://github.com/kubernetes-sigs/kind/issues/99
  extraPortMappings:
  - containerPort: 30100
    hostPort: 30100
  - containerPort: 30101
    hostPort: 30101
  - containerPort: 30102
    hostPort: 30102
...
```

So to provision such a cluster, do this:

```
$ kind create cluster --name my-cluster --config kind/kind-config-extra-ports.yaml
```

At this case, you can use these ports as the `NodePort`s to expose to host, your laptop, directly.

> Note:
> 1. You may use these ports for your Ingress -- check out below topic to see how;
> 2. You may expose more ports if you want

### Enable Ingress Support

As we've explored the way how to use `NodePort` to expose services to the external world, Ingress of course can follow exactly the same way.

So let's take `traefik` as an example:

```Bash
$ cat <<EOF > kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-rbac.yaml
  - https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-ds.yaml

patchesStrategicMerge:
  - |-
    apiVersion: v1
    kind: Service
    metadata:
      name: traefik-ingress-service
      namespace: kube-system
    spec:
      type: NodePort
      selector:
        k8s-app: traefik-ingress-lb
      ports:
        - protocol: TCP
          port: 80
          nodePort: 30100       # <-- 2. add this nodePort binding to one of the node ports exposed
          name: web
        - protocol: TCP
          port: 8080
          nodePort: 30101       # <-- 3. add this nodePort binding to another one of the node ports exposed
          name: admin
EOF
$ kubectl apply -k .
```
Test it out:

```sh
$ kubectl create deployment web --image=nginx
$ kubectl expose deployment web --port=80
$ kubectl apply -f - <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-test
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
    - host: www.example.com
      http:
        paths:
          - path: /
            backend:
              serviceName: web
              servicePort: 80
EOF

$ curl -s -H "Host: www.example.com" http://localhost:30100 | grep title
<title>Welcome to nginx!</title>
```

### Enable Metrics

To enable metrics by `metrics-server`:

```sh
$ git clone https://github.com/kubernetes-incubator/metrics-server.git
$ kubectl create -f metrics-server/deploy/1.8+/

$ kubectl -n kube-system edit deployment metrics-server
...
spec:
  containers:
  - image: k8s.gcr.io/metrics-server-amd64:v0.3.1
    imagePullPolicy: Always
    name: metrics-server
    command:                  #<-- Add some lines, start
    - /metrics-server
    - --kubelet-preferred-address-types=InternalIP
    - --kubelet-insecure-tls  #<-- Add some lines, end
    resources: {}
...
```

Wait for a couple of minutes:

```sh
$ kubectl top node
NAME                         CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
kind-cluster-control-plane   226m         2%     562Mi           28%
kind-cluster-worker          80m          1%     278Mi           13%
kind-cluster-worker2         62m          0%     221Mi           11%
kind-cluster-worker3         63m          0%     238Mi           11%
```

### Enable Instant Monitoring

To enable instant monitoring by tools like `kube-ops-view`.

1. For one-off use:

```sh
$ kubectl proxy --accept-hosts '.*' &
$ docker run -it -p 8080:8080 -e CLUSTERS=http://docker.for.mac.localhost:8001 hjacobs/kube-ops-view
```

Open browser and navigate to: http://localhost:8080

2. To install:

```sh
$ git clone https://github.com/hjacobs/kube-ops-view.git
$ kubectl apply -f kube-ops-view/deploy

$ kubectl port-forward service/kube-ops-view 8080:80
```

Open browser and navigate to: http://localhost:8080

> Ref: https://github.com/hjacobs/kube-ops-view

### Enable Kubernetes Dashboard

```sh
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.1.0/aio/deploy/recommended.yaml
$ kubectl proxy
```

To access it, we have to do something like this and get the access token:

```sh
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system
EOF

$ kubectl -n kubernetes-dashboard describe secret \
  $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
```

Now access Dashboard:

```sh
$ open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

### Enable Routing to Services

Sometimes what we need is just a quick routing to a specific service without a need of Ingress or Loadbalancer.

Other than ad-hoc proxying by using `kubectl port-forward`, we can use `socat` to proxy the route to it.

```sh
# Assuming we have nginx deployed, in default namespace
$ kubectl create deployment nginx --image=nginx

# We can then expose it as service, with a NodePort which can't be accessible in kind
$ kubectl expose deployment nginx --type=NodePort --port=80
$ SVC_PORT="$(kubectl get svc/nginx -o json | jq '.spec.ports[0].nodePort')"

# Create this proxy container
$ CLUSTER_NAME=my-cluster   # the cluster name, which is `kind` by default
$ docker run -d --restart always \
    --name kind-proxy-${SVC_PORT} \
    --publish 127.0.0.1:${SVC_PORT}:${SVC_PORT} \
    --link ${CLUSTER_NAME}-control-plane:target \
    --network kind \
    alpine/socat -dd \
    tcp-listen:${SVC_PORT},fork,reuseaddr tcp-connect:target:${SVC_PORT}

# Now we can access it directly
$ curl -s http://127.0.0.1:$SVC_PORT | grep title
<title>Welcome to nginx!</title>
```

### Enable Loadbalancer support by MetalLB

Loadbalancer support is important in Kubernetes in some cases and [MetalLB](https://metallb.universe.tf/) can help.

Unfortunately, `type: LoadBalancer` can't work well in `kind` in MacOS due to how Docker Desktop is built os MacOS.

**So this approach can work in Linux only (not sure about Windows), for now.**

```sh
# Retrieve the Docker bridge subnet named `kind`, which is used by kind, e.g. 172.18.0.0/16
# Then get the first two sections only, like 172.18
DOCKER_KIND_SUBNET=$(docker network inspect kind -f "{{(index .IPAM.Config 0).Subnet}}" | cut -d '.' -f1,2)

# Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/namespace.yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - $DOCKER_KIND_SUBNET.255.1-$DOCKER_KIND_SUBNET.255.250
EOF
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
```

To test it:

```sh
$ kubectl create deployment nginx --image=nginx
$ kubectl expose deployment nginx --name=nginx --port=80 --target-port=80 --type=LoadBalancer

$ kubectl get svc
NAME         TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)        AGE
kubernetes   ClusterIP      10.96.0.1      <none>          443/TCP        26m
nginx        LoadBalancer   10.96.25.182   172.18.255.1    80:30565/TCP   5s

$ LB_IP=$( kubectl get svc nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' )
$ curl -s $LB_IP | grep title
<title>Welcome to nginx!</title>
```

### Enable Non-GA Features

Here I provide a sample [`kind-config-advanced.yaml`](kind/kind-config-advanced.yaml) file on how to enable more features, including enabling non-GA kubernetes features.
Basically `kind` can **patch** the configuration files as well.

### Spin Up Local Docker Registry

It's very useful to have a local Docker registry while spinning up Kubernetes cluster by `kind`.
The doc is [here](https://kind.sigs.k8s.io/docs/user/local-registry/).

And I provide a simple script file, [here](kind/kind-with-local-registry.sh), for you as well.

To do that, you may simply run this:

```
$ git clone https://github.com/brightzheng100/kube4dev.git
$ cd kube4dev/kind
$ ./kind-with-local-registry.sh
```

Then you will have a `kind`-powered Kubernetes cluster, with:
- 1 x Master Node
- 3 x Worker Node
- 1 x local Docker Registry, which is accessible from Kubernetes cluster, with prefix of `registry:5000/`. For example, `registry:5000/busybox`

> Notes:
1. You may customize the cluster creation script by exporting below variables to replace the default:
    - KIND_CLUSTER_NAME, defaults to "my-cluster"
    - KIND_CLUSTER_VERSION, defaults to "kindest/node:latest"
    - REGISTRY_CONTAINER_NAME, defaults to "kind-registry"
    - REGISTRY_CONTAINER_PORT, defaults to "5000"
2. This way of spinning up Registry has one known issue: the process within container can access it only when configured like this:
```yaml
  hostNetwork: true
  dnsPolicy: ClusterFirstWithHostNet
```

## Known Issues

### 1. The provision process won't work if PSP is enabled while bootstrapping

By right we can enable PSP by simply patching the bootstrapping YAML:

```yaml
kind: Cluster
apiVersion: kind.sigs.k8s.io/v1alpha3
kubeadmConfigPatches:
- |
  apiVersion: kubeadm.k8s.io/v1beta2
  kind: ClusterConfiguration
  metadata:
    name: config
  apiServer:
    extraArgs:
      enable-admission-plugins: NodeRestriction,PodSecurityPolicy
  ...
```

But it won't work in `kind` (and maybe the whole `kubeadm`-based bootstrapping approach?).
For now, it _may_ work only to enable it **after** the bootstrapping is done, with proper PSP and RBAC permissions granted.

> Ref: https://github.com/kubernetes-sigs/kind/issues/973
