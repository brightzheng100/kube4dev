
# kind - Kubernetes in Docker

## Prerequisites

- Docker (Desktop) is installed


## Installation

The simple goal: to provision a Kubernetes cluster with **1 Master** + **3 Workers**

```sh
$ curl -Lo ./kind https://github.com/kubernetes-sigs/kind/releases/download/v0.6.0/kind-$(uname)-amd64
$ chmod +x ./kind && mv ./kind /usr/local/bin/
$ kind version
kind v0.6.0 go1.13.4 darwin/amd64

$ git clone https://github.com/brightzheng100/kube4dev.git
$ cd kube4dev

$ kind create cluster --name my-cluster --config kind/kind-config-basic.yaml
```

> Note:
> 1. You may specify `--image kindest/node:<VERSION>` to provision designated/desired version of Kubernetes, instead of `latest` by default, which is subject to change from time to time;
> 2. Above process will quickly provision a Kubernetes cluster with below components:
>     - 1 x Master "node"
>     - 3 x Worker "nodes"
> 3. See **[`Advanced Topics`](#advanced-topics)** for how to enable some interesting features


## Usage

```sh
$ kubectl config get-contexts
CURRENT   NAME              CLUSTER           AUTHINFO          NAMESPACE
*         kind-my-cluster   kind-my-cluster   kind-my-cluster

$ kubectl get nodes
NAME                       STATUS   ROLES    AGE   VERSION
my-cluster-control-plane   Ready    master   80s   v1.16.3
my-cluster-worker          Ready    <none>   42s   v1.16.3
my-cluster-worker2         Ready    <none>   42s   v1.16.3
my-cluster-worker3         Ready    <none>   42s   v1.16.3

$ kubectl get ns
NAME              STATUS   AGE
default           Active   2m30s
kube-node-lease   Active   2m33s
kube-public       Active   2m33s
kube-system       Active   2m33s

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
CONTAINER ID        IMAGE                              COMMAND                  CREATED             STATUS              PORTS                       NAMES
927788d985f5        kindest/node:v1.16.3               "/usr/local/bin/entr…"   10 minutes ago      Up 10 minutes       127.0.0.1:62221->6443/tcp   my-cluster-control-plane
1cef422cfb40        kindest/node:v1.16.3               "/usr/local/bin/entr…"   10 minutes ago      Up 10 minutes                                   my-cluster-worker3
3a006f6e2277        kindest/node:v1.16.3               "/usr/local/bin/entr…"   10 minutes ago      Up 10 minutes                                   my-cluster-worker
78b1de089fa4        kindest/node:v1.16.3               "/usr/local/bin/entr…"   10 minutes ago      Up 10 minutes                                   my-cluster-worker2

$ docker exec -it my-cluster-control-plane bash
root@my-cluster-control-plane:/# hostname
my-cluster-control-plane
root@my-cluster-control-plane:/# ls /etc/kubernetes/manifests/
etcd.yaml  kube-apiserver.yaml  kube-controller-manager.yaml  kube-scheduler.yaml
root@my-cluster-control-plane:/# systemctl status kubelet.service
● kubelet.service - kubelet: The Kubernetes Node Agent
   Loaded: loaded (/kind/systemd/kubelet.service; enabled; vendor preset: enabled)
  Drop-In: /etc/systemd/system/kubelet.service.d
           └─10-kubeadm.conf
   Active: active (running) since Sat 2019-11-16 13:58:07 UTC; 28min ago
     Docs: http://kubernetes.io/docs/
 Main PID: 233 (kubelet)
    Tasks: 27 (limit: 2359)
   Memory: 57.3M
   ...
```

> Note: 
> 1. Frankly, after `docker exec` into the "node", you really can't differentiate whether you're in a real VM or a Docker container -- the components are exactly the same as what I have by using `kubeadm`;
> 2. You may check out [this repo](https://github.com/brightzheng100/kubernetes-the-kubeadm-way) to see how to provision a **real and full-fledged** `kubeadm`-based cluster on GCP.

### Use Desired CNI

You may use other CNI like `calico`, or `weave-net` instead of default `kindnet`.

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

> Note: do check out your desired CNI to learn what `podSubnet` is required to set

I already provide a [`kind-cofig-advanced.yaml`](kind/kind-cofig-advanced.yaml) which would help you provision a highly customized Kubernetes cluster with default CNI disabled.

To provision such a cluster, do this:

```
$ kind create cluster --name my-cluster --config kind/kind-config-advanced.yaml
```

Lastly, you can create your desired overlay network.
Let's take `weave-net` as an example:

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

```
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

```
$ kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-rbac.yaml
$ kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-ds.yaml
$ kubectl edit service/traefik-ingress-service -n kube-system
```

Make sure we update `traefik`'s service:

```sh
$ kubectl apply -n kube-system -f - <<EOF
kind: Service
apiVersion: v1
metadata:
  name: traefik-ingress-service
  namespace: kube-system
spec:
  type: NodePort          # <-- 1. change the default ClusterIp to NodePort
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
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta6/aio/deploy/recommended.yaml
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
apiVersion: rbac.authorization.k8s.io/v1beta1
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
