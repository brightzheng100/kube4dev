# Vagrant + VirtualBox

## Prerequisites

- VirtualBox is installed

```sh
$ vboxmanage --version
6.0.14r133895
```

## Install `vagrant` in MacBook

```sh
$ brew cask install vagrant

$ vagrant --version
Vagrant 2.2.6
```

## Provision Kubernetes Cluster

### Provision VMs

The simple goal: to provision a Kubernetes cluster with **1 Master** + **1 Workers**

```sh
$ git clone https://github.com/brightzheng100/kube4dev.git
$ cd kube4dev/vagrant

$ vagrant up
$ vagrant status
Current machine states:

k8s-master1               running (virtualbox)
k8s-worker1               running (virtualbox)
...
```

> Note: 
> - below components are already installed on each host: `docker`, `kubelet`, `kubeadm`, `kubectl`, `kubernetes-cni`
> - IPs
>   - k8s-master1: 192.168.205.10
>   - k8s-worker1: 192.168.205.11

### Bootstrap Kubernetes in Master VM

> Important tip: before running the `kubeadm init`, do check out the requirement of setting `pod-network-cidr` properly for your desired CNI.
> For example:
> - Flannel:  `--pod-network-cidr=10.244.0.0/16`
> - Canel:    `--pod-network-cidr=10.244.0.0/16`
> - Calico:   `--pod-network-cidr=192.168.0.0/16`
> - Cilium:   `--pod-network-cidr=10.217.0.0/16`

```sh
$ vagrant ssh k8s-master1

$ sudo kubeadm init \
  --apiserver-advertise-address=192.168.205.10 \
  --ignore-preflight-errors='NumCPU' \
  --pod-network-cidr=10.244.0.0/16
```

> Logs:

```
...
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.205.10:6443 --token ugc9e5.qq68a4civehymoir \
    --discovery-token-ca-cert-hash sha256:591559f9de63bba2e58634a7e7fced0e1ba80a3074172a293cc014cfab6d4ce2
```

Let's check it out:

```sh
$ mkdir -p $HOME/.kube &&
  sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config &&
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

$ kubectl get nodes
NAME          STATUS     ROLES    AGE   VERSION
k8s-master1   NotReady   master   36s   v1.16.3

$ kubectl get pod -n kube-system
NAME                                  READY   STATUS    RESTARTS   AGE
coredns-5644d7b6d9-7465m              0/1     Pending   0          4m26s
coredns-5644d7b6d9-grh4s              0/1     Pending   0          4m26s
etcd-k8s-master1                      1/1     Running   0          3m49s
kube-apiserver-k8s-master1            1/1     Running   0          3m25s
kube-controller-manager-k8s-master1   1/1     Running   0          3m37s
kube-proxy-cx867                      1/1     Running   0          4m26s
kube-proxy-mx6km                      1/1     Running   0          2m33s
kube-scheduler-k8s-master1            1/1     Running   0          3m39s
```

Now it's time to install CNI.
Here we'd try out `canal`:

```sh
$ kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/canal.yaml
configmap/canal-config created
customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ippools.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/hostendpoints.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/clusterinformations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworksets.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networksets.crd.projectcalico.org created
clusterrole.rbac.authorization.k8s.io/calico-node created
clusterrole.rbac.authorization.k8s.io/flannel created
clusterrolebinding.rbac.authorization.k8s.io/canal-flannel created
clusterrolebinding.rbac.authorization.k8s.io/canal-calico created
daemonset.apps/canal created
serviceaccount/canal created
```

Wait for a while and check it again:

```sh
$ kubectl get pod -n kube-system
NAME                                  READY   STATUS    RESTARTS   AGE
canal-h5hp8                           2/2     Running   0          113s
canal-wbsg5                           2/2     Running   0          113s
coredns-5644d7b6d9-7465m              1/1     Running   0          8m21s
coredns-5644d7b6d9-grh4s              1/1     Running   0          8m21s
etcd-k8s-master1                      1/1     Running   0          7m44s
kube-apiserver-k8s-master1            1/1     Running   0          7m20s
kube-controller-manager-k8s-master1   1/1     Running   0          7m32s
kube-proxy-cx867                      1/1     Running   0          8m21s
kube-proxy-mx6km                      1/1     Running   0          6m28s
kube-scheduler-k8s-master1            1/1     Running   0          7m34s
```

### Join Worker Node(s)

From laptop, open another console:

```sh
$ vagrant ssh k8s-worker1

$ sudo kubeadm join 192.168.205.10:6443 --token ugc9e5.qq68a4civehymoir \
    --discovery-token-ca-cert-hash sha256:591559f9de63bba2e58634a7e7fced0e1ba80a3074172a293cc014cfab6d4ce2
```

> Logs:

```
...
This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster
```

### Double Check in Master VM

Let's work in Master VM (as the kubectl env is ready and handy there)

```sh
$ kubectl get nodes
NAME          STATUS   ROLES    AGE     VERSION
k8s-master1   Ready    master   9m11s   v1.16.3
k8s-worker1   Ready    <none>   6m58s   v1.16.3

$ kubectl create deployment nginx --image=nginx

$ kubectl get po
NAME                     READY   STATUS    RESTARTS   AGE
nginx-86c57db685-krjfj   1/1     Running   0          77s
```

## Clean Up

```sh
$ vagrant destroy
```

## FAQ

### cgroup driver

I encountered very weird issue while using `systemd` as Docker's cgconfig driver:

```sh
# journalctl -fu kubelet.service
...
Error while processing event ("/sys/fs/cgroup/memory/libcontainer_20221_systemd_test_default.slice": 0x40000100 == IN_CREATE|IN_ISDIR): readdirent: no such file or directory
...
```

To current workaround was to change the driver from `systemd` to `cgroupfs`.

> Ref: https://github.com/kubernetes/kubernetes/issues/76531

### can't `kubectl exec` into container

```sh
$ kubectl run busybox --image=busybox -it --rm --restart=Never -- sh
If you don't see a command prompt, try pressing enter.
Error attaching, falling back to logs: unable to upgrade connection: pod does not exist
pod "busybox" deleted
Error from server (NotFound): the server could not find the requested resource ( pods/log busybox)

$ kubectl -v=9 run busybox --image=busybox -it --rm --restart=Never -- sh
...
I1110 04:42:08.997990   11345 helpers.go:199] server response object: [{
  "metadata": {},
  "status": "Failure",
  "message": "the server could not find the requested resource ( pods/log busybox)",
  "reason": "NotFound",
  "details": {
    "name": "busybox",
    "kind": "pods/log"
  },
  "code": 404
}]
F1110 04:42:08.998008   11345 helpers.go:114] Error from server (NotFound): the server could not find the requested resource ( pods/log busybox)
```

The issue was caused by how Vagrant sets up VM:
- Vagrant creates two network interfaces for each machine. eth0 is NAT networked, eth1 is a private network.
- The main Kubernetes interface is on eth1.
- In order for the worker to properly join the master, I had to explicitly state the `--apiserver-advertise-address` to point to eth1.

So have a check:

```
$ kubectl get nodes -o wide
NAME          STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
k8s-master1   Ready    master   15m   v1.16.3   10.0.2.15     <none>        Ubuntu 16.04.6 LTS   4.4.0-166-generic   docker://18.9.7
k8s-worker1   Ready    <none>   13m   v1.16.3   10.0.2.15     <none>        Ubuntu 16.04.6 LTS   4.4.0-166-generic   docker://18.9.7
```

See the IP is the NAT IP, instead of the right IP we use for `--apiserver-advertise-address=192.168.205.10`

The workaround now is, update both Master and Worker nodes:

```sh
$ sudo vi /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
---
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
# ADD THIS LINE IN MASTER
Environment="KUBELET_EXTRA_ARGS=--node-ip=192.168.205.10"


Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
# ADD THIS LINE IN WORKER
Environment="KUBELET_EXTRA_ARGS=--node-ip=192.168.205.11"
---
```

Then restart:

```
$ sudo systemctl daemon-reload && sudo systemctl restart kubelet
```

Now, the problem is fixed. Let's verify:

```sh
$ kubectl get nodes -o wide
NAME          STATUS   ROLES    AGE   VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
k8s-master1   Ready    master   20m   v1.16.3   192.168.205.10   <none>        Ubuntu 16.04.6 LTS   4.4.0-166-generic   docker://18.9.7
k8s-worker1   Ready    <none>   18m   v1.16.3   192.168.205.11   <none>        Ubuntu 16.04.6 LTS   4.4.0-166-generic   docker://18.9.7

$ kubectl run busybox --image=busybox -it --rm --restart=Never -- sh
If you don't see a command prompt, try pressing enter.
/ # ps
PID   USER     TIME  COMMAND
    1 root      0:00 sh
    6 root      0:00 ps
```

> Ref: https://medium.com/@joatmon08/playing-with-kubeadm-in-vagrant-machines-part-2-bac431095706
