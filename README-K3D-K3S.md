
# k3s by k3d

[k3s](https://k3s.io/) is a highly available, certified Kubernetes distribution designed for production workloads in unattended, resource-constrained, remote locations or inside IoT appliances.

[k3d](https://k3d.io/) is a lightweight wrapper to run k3s in Docker.


## Prerequisites

- Docker (Desktop) is installed


## Install k3d

```sh
# By wget
$ wget -q -O - https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash

# Or by curl
$ curl -L -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
```

Let's verify:

```sh
$ k3d version
k3d version v4.4.7
k3s version v1.21.2-k3s1 (default)
```


## Provision Kubernetes Cluster

The simple goal is to provision a Kubernetes cluster with **1 Master** + **3 Workers**.

```sh
$ git clone https://github.com/brightzheng100/kube4dev.git && cd kube4dev
```

### Purely by CLI

We can use pure command line + parameters to achieve that:

```sh
$ k3d cluster create k3s-cluster --servers 1 --agents 3
```

OUTPUT:
```
INFO[0000] Prep: Network
INFO[0005] Created network 'k3d-k3s-cluster' (ca0aec42c19653d0c82ce632846ee1a25ef75556e1ecac5e429fe61fbb21c3fc)
INFO[0005] Created volume 'k3d-k3s-cluster-images'
INFO[0006] Creating node 'k3d-k3s-cluster-server-0'
INFO[0010] Pulling image 'docker.io/rancher/k3s:v1.21.2-k3s1'
INFO[0021] Creating node 'k3d-k3s-cluster-agent-0'
INFO[0021] Creating node 'k3d-k3s-cluster-agent-1'
INFO[0022] Creating node 'k3d-k3s-cluster-agent-2'
INFO[0022] Creating LoadBalancer 'k3d-k3s-cluster-serverlb'
INFO[0026] Pulling image 'docker.io/rancher/k3d-proxy:v4.4.7'
INFO[0032] Starting cluster 'k3s-cluster'
INFO[0032] Starting servers...
INFO[0032] Starting Node 'k3d-k3s-cluster-server-0'
INFO[0041] Starting agents...
INFO[0041] Starting Node 'k3d-k3s-cluster-agent-0'
INFO[0052] Starting Node 'k3d-k3s-cluster-agent-1'
INFO[0060] Starting Node 'k3d-k3s-cluster-agent-2'
INFO[0068] Starting helpers...
INFO[0068] Starting Node 'k3d-k3s-cluster-serverlb'
INFO[0071] (Optional) Trying to get IP of the docker host and inject it into the cluster as 'host.k3d.internal' for easy access
INFO[0074] Successfully added host record to /etc/hosts in 5/5 nodes and to the CoreDNS ConfigMap
INFO[0074] Cluster 'k3s-cluster' created successfully!
INFO[0074] --kubeconfig-update-default=false --> sets --kubeconfig-switch-context=false
INFO[0074] You can now use it like this:
kubectl config use-context k3d-k3s-cluster
kubectl cluster-info
```

### By CLI + Config File

It's also common, or even recommended, to compile a config file, especially when there are many advanced options, and feed it for the CLI:

```sh
$ k3d cluster create --config k3d/k3d-basic.yaml
```


## Verify

```sh
# Check the Docker containers
$ docker ps
CONTAINER ID   IMAGE                           COMMAND                  CREATED          STATUS          PORTS                             NAMES
eceeff1ec1d7   rancher/k3d-proxy:v4.4.7        "/bin/sh -c nginx-pr…"   49 seconds ago   Up 10 seconds   80/tcp, 0.0.0.0:62326->6443/tcp   k3d-k3s-cluster-serverlb
a0256c9f7c3e   rancher/k3s:v1.21.2-k3s1        "/bin/k3s agent"         49 seconds ago   Up 20 seconds                                     k3d-k3s-cluster-agent-2
8b87fac3d6d7   rancher/k3s:v1.21.2-k3s1        "/bin/k3s agent"         49 seconds ago   Up 28 seconds                                     k3d-k3s-cluster-agent-1
04db0e94501a   rancher/k3s:v1.21.2-k3s1        "/bin/k3s agent"         49 seconds ago   Up 38 seconds                                     k3d-k3s-cluster-agent-0
a25a6dffa575   rancher/k3s:v1.21.2-k3s1        "/bin/k3s server --t…"   49 seconds ago   Up 46 seconds                                     k3d-k3s-cluster-server-0

# Check the Kubernetes context
$ kubectl config get-contexts
CURRENT   NAME              CLUSTER           AUTHINFO                NAMESPACE
*         k3d-k3s-cluster   k3d-k3s-cluster   admin@k3d-k3s-cluster

# Check the Kubernetes nodes
$ kubectl get nodes
NAME                       STATUS   ROLES                  AGE     VERSION
k3d-k3s-cluster-agent-2    Ready    <none>                 3m1s    v1.21.2+k3s1
k3d-k3s-cluster-server-0   Ready    control-plane,master   3m26s   v1.21.2+k3s1
k3d-k3s-cluster-agent-0    Ready    <none>                 3m18s   v1.21.2+k3s1
k3d-k3s-cluster-agent-1    Ready    <none>                 3m9s    v1.21.2+k3s1

# Deploy nginx
$ kubectl create deployment nginx --image=nginx
deployment.apps/nginx created

$ kubectl get deploy,pod
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   1/1     1            1           21s

NAME                         READY   STATUS    RESTARTS   AGE
pod/nginx-6799fc88d8-stdg8   1/1     Running   0          21s
```


## Usage

Overall, `k3s` is quite similar to `kind`.

But I'd have to say that `k3s` may have offered better UX for Kubernetes users.

```sh
$ k3d --help
https://k3d.io/
k3d is a wrapper CLI that helps you to easily create k3s clusters inside docker.
Nodes of a k3d cluster are docker containers running a k3s image.
All Nodes of a k3d cluster are part of the same docker network.

Usage:
  k3d [flags]
  k3d [command]

Available Commands:
  cluster      Manage cluster(s)
  completion   Generate completion scripts for [bash, zsh, fish, powershell | psh]
  config       Work with config file(s)
  help         Help about any command
  image        Handle container images.
  kubeconfig   Manage kubeconfig(s)
  node         Manage node(s)
  registry     Manage registry/registries
  version      Show k3d and default k3s version

Flags:
  -h, --help         help for k3d
      --timestamps   Enable Log timestamps
      --trace        Enable super verbose output (trace logging)
      --verbose      Enable verbose output (debug logging)
      --version      Show k3d and default k3s version

Use "k3d [command] --help" for more information about a command.
```

And I'd like to highlight some of them:

- node management;
- registry management

### Node Management

There is no `node management` in `kind`, but we can do this in `k3d`:

```sh
$ k3d node
Manage node(s)

Usage:
  k3d node [flags]
  k3d node [command]

Available Commands:
  create      Create a new k3s node in docker
  delete      Delete node(s).
  list        List node(s)
  start       Start an existing k3d node
  stop        Stop an existing k3d node

Flags:
  -h, --help   help for node

Global Flags:
      --timestamps   Enable Log timestamps
      --trace        Enable super verbose output (trace logging)
      --verbose      Enable verbose output (debug logging)
```

Now, let's do some experiments:

```sh
# List all nodes
$ k3d node list
NAME                       ROLE           CLUSTER       STATUS
k3d-k3s-cluster-agent-0    agent          k3s-cluster   running
k3d-k3s-cluster-agent-1    agent          k3s-cluster   running
k3d-k3s-cluster-agent-2    agent          k3s-cluster   running
k3d-k3s-cluster-server-0   server         k3s-cluster   running
k3d-k3s-cluster-serverlb   loadbalancer   k3s-cluster   running

# Let's add one more node namely `new-agent-4` to the cluster as "agent" -- the worker node
$ k3d node create new-agent-4 --cluster k3s-cluster --role agent --replicas 1

# So now we have 4 agents
$ k3d node list
NAME                       ROLE           CLUSTER       STATUS
k3d-k3s-cluster-agent-0    agent          k3s-cluster   running
k3d-k3s-cluster-agent-1    agent          k3s-cluster   running
k3d-k3s-cluster-agent-2    agent          k3s-cluster   running
k3d-k3s-cluster-server-0   server         k3s-cluster   running
k3d-k3s-cluster-serverlb   loadbalancer   k3s-cluster   running
k3d-new-agent-4-0          agent          k3s-cluster   running

# Of course, you can delete any of them too
$ k3d node delete k3d-new-agent-4-0

# And now we have 3 agents
$ k3d node list
NAME                       ROLE           CLUSTER       STATUS
k3d-k3s-cluster-agent-0    agent          k3s-cluster   running
k3d-k3s-cluster-agent-1    agent          k3s-cluster   running
k3d-k3s-cluster-agent-2    agent          k3s-cluster   running
k3d-k3s-cluster-server-0   server         k3s-cluster   running
k3d-k3s-cluster-serverlb   loadbalancer   k3s-cluster   running
```

We can start or stop nodes too by `k3d node stop NAME` and `k3d node stop NAME` accordingly.

### Registry Management

`kind` does offer some scripts to spin up a registry, as I mentioned [here](https://github.com/brightzheng100/kube4dev/blob/master/README-KIND.md#spin-up-local-docker-registry), or the official docs [here](https://kind.sigs.k8s.io/docs/user/local-registry/).

But `k3d` offers native support for it:

```sh
$ k3d registry
Manage registry/registries

Usage:
  k3d registry [flags]
  k3d registry [command]

Aliases:
  registry, registries, reg

Available Commands:
  create      Create a new registry
  delete      Delete registry/registries.
  list        List registries

Flags:
  -h, --help   help for registry

Global Flags:
      --timestamps   Enable Log timestamps
      --trace        Enable super verbose output (trace logging)
      --verbose      Enable verbose output (debug logging)
```

We may not have a registry based on the minimalist way of cluster provisioning but let's explore the way `k3d` offers.

```sh
# No registry there
$ k3d registry list
NAME   ROLE   CLUSTER   STATUS

# Let's create a registry
$ k3d registry create my-k3s-registry
INFO[0000] Creating node 'k3d-my-k3s-registry'
INFO[0004] Pulling image 'docker.io/library/registry:2'
INFO[0008] Successfully created registry 'k3d-my-k3s-registry'
INFO[0008] Starting Node 'k3d-my-k3s-registry'
INFO[0009] Successfully created registry 'k3d-my-k3s-registry'
...

# Now it can be listed out
$ k3d registry list
NAME                  ROLE       CLUSTER   STATUS
k3d-my-k3s-registry   registry             running
```

If you think through the workflow you would realize that there are two major steps:

- Build, tag and push the image to the registry
- Reference the image from Kubernetes

So to access it, we have to update the `/etc/hosts` in Mac/Linux or the similar in Windows.

```sh
$ echo "127.0.0.1 k3d-my-k3s-registry" | sudo tee -a /etc/hosts
```

Now, how the `k3d`-powered cluster nodes can access this registry?

Theoretically, it's quite straightforward: in Docker's custom network, the nodes can be discoverable by names.

But there is an issue while creating registry, e.g. by `k3d registry create my-k3s-registry`: we can't specify the Docker network so actually it's been provisioned within the default Docker network!

So if we provision the cluster first and then the register, we MUST attach the registry container to the same Docker network:

```sh
# Connect the container to the network
$ docker network connect k3d-k3s-cluster k3d-my-k3s-registry
```

But this still won't work as if I try push the image to it and reference it from `k3d`-powered cluster, I would get this error:

```log
Warning  Failed     9s    kubelet            Failed to pull image "k3d-my-k3s-registry:5000/mynginx:v0.1": rpc error: code = Unknown desc = failed to pull and unpack image "k3d-my-k3s-registry:5000/mynginx:v0.1": failed to resolve reference "k3d-my-k3s-registry:5000/mynginx:v0.1": failed to do request: Head "https://k3d-my-k3s-registry:5000/v2/mynginx/manifests/v0.1": http: server gave HTTP response to HTTPS client
```

There is simply because we haven't registered the registry as "insecure-registries". So before I figure out a simple solution to make it sequence-free, let's follow the "official process".

There are two options:

- Approach 1: Create the cluster with a flag of `--registry-create` so that the cluster will be created with a registry created and integrated in one shot; 

- Approach 2: Create a registry first and then specify the `--registry-use` flag to use it when creating the cluster.

Let's take the approach 2 to walk it through, step by step:

```sh
# Let's create a registry, if you haven't yet
# If you check carefully, it's provisioned in default `bridge` network (and will be attached later if we `use` it in k3d cluster privisioning)
$ k3d registry create my-k3s-registry

# Note: if the previous cluster with the same name still exists, delete it by: k3d cluster delete k3s-cluster
# Create a cluster to use the newly created registry
$ k3d cluster create --config k3d/k3d-basic.yaml --registry-use "k3d-my-k3s-registry:5000"
# Or by using one configuration file only, like this:
# k3d cluster create --config k3d/k3d-with-registry.yaml

# Retrieve the exposed container port for registry
$ export K3S_REGISTRY_PORT=`k3d registry list -o json | jq -r '.[].portMappings."5000/tcp"[].HostPort'`

# Prepare the Docker image
$ docker pull nginx
$ docker tag nginx:latest k3d-my-k3s-registry:${K3S_REGISTRY_PORT}/mynginx:v0.1

# Push it from the Docker host so the exposed port must be used
$ docker push k3d-my-k3s-registry:${K3S_REGISTRY_PORT}/mynginx:v0.1

# While referencing from Kubernetes, it's fine to use the internal port, which is 5000
$ kubectl run mynginx --image k3d-my-k3s-registry:5000/mynginx:v0.1

# Try it out in our cluster and it works
$ kubectl get pod
NAME      READY   STATUS    RESTARTS   AGE
mynginx   1/1     Running   0          14s

# Take a look at the image used
$ kubectl get pod mynginx -o json | jq -r ".spec.containers[0].image"
k3d-my-k3s-registry:63397/mynginx:v0.1
```


## Clean Up

```sh
$ k3d cluster delete k3s-cluster
```

OUTPUT:
```
INFO[0000] Deleting cluster 'k3s-cluster'
INFO[0001] Deleted k3d-k3s-cluster-serverlb
INFO[0001] Deleted k3d-k3s-cluster-agent-2
INFO[0002] Deleted k3d-k3s-cluster-agent-1
INFO[0002] Deleted k3d-k3s-cluster-agent-0
INFO[0002] Deleted k3d-k3s-cluster-server-0
INFO[0002] Deleting cluster network 'k3d-k3s-cluster'
INFO[0006] Deleting image volume 'k3d-k3s-cluster-images'
INFO[0006] Removing cluster details from default kubeconfig...
INFO[0006] Removing standalone kubeconfig file (if there is one)...
INFO[0006] Successfully deleted cluster k3s-cluster!
```

If you created the registry too, delete it:

```sh
$ k3d registry delete my-k3s-registry
INFO[0001] Deleted k3d-my-k3s-registry
```

## Advanced Topics

