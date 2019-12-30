# OKD in Docker

## Preresuisites

### Docker

1. Docker CE Desktop (>=1.22) is installed
2. Adjust Docker CE Desktop's CPU to 6 and RAM to 8G -- a bit more or less may still work
3. In the Daemon tab, add `172.30.0.0/16` to the insecure registries list, then apply and restart
4. Create /var/lib/kubelet/device-plugins directory
```sh
sudo mkdir /var/lib/kubelet
sudo mkdir /var/lib/kubelet/device-plugins
sudo chgrp staff /var/lib/kubelet/device-plugins
sudo chmod 770 /var/lib/kubelet/device-plugins
```
5. In the File Sharing tab, add /var/lib/kubelet/device-plugins to the list of directories that can be bind-mounted.
6. Save and apply the changes

### Other Components

1. Install socat

```sh
$ brew install socat
```

2. Install oc v3.11

```sh
wget https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-mac.zip

tar -xf openshift-origin-client-tools-v3.11.0-0cbc58b-mac.zip
chmod +x oc
mv oc /usr/local/bin/
```

> Note: to have multiple `oc` versions, say v3 and v4, rename v3 as `oc3`

## Start the cluster

```sh
$ oc cluster up --base-dir=${HOME}/openshift.local.clusterup
...
Login to server ...
Creating initial project "myproject" ...
Server Information ...
OpenShift server started.

The server is accessible via web console at:
    https://127.0.0.1:8443

You are logged in as:
    User:     developer
    Password: <any value>

To login as administrator:
    oc login -u system:admin
```

> Note: When you start the cluster it will, by default, create a directory in the current directory.

## Play with it

### Login as Cluster Admin

```sh
$ oc login -u system:admin
```

### Check cluster status

```sh
$ oc cluster status
Web console URL: https://127.0.0.1:8443/console/

Config is at host directory
Volumes are at host directory
Persistent volumes are at host directory /Users/brightzheng/openshift.local.clusterup/openshift.local.pv
Data will be discarded when cluster is destroyed
```

### Hello World

Let's quickly deploy a hello world app there.

```sh
$ oc run nginx --image=bitnami/nginx
deploymentconfig.apps.openshift.io/nginx created

$ oc get deploy,po
NAME                          DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.extensions/nginx   1         1         1            1           15s

NAME                         READY     STATUS    RESTARTS   AGE
pod/nginx-7c69b7cfd7-gfjpw   1/1       Running   0          15s
```

> Notes: 
> 1. Of course you can use `kubectl` instead of `oc` -- they're interchangea in above cases;
> 2. If you used `nginx` image instead of `bitnami/nginx`, the pod would fail to start because the default `nginx` requires `root` permission, which is not allowed in OKD by default.

### How it works?

You may curious how it works.

Try this out and you may know now why we simply call it `OKD in Docker`.

```sh
$ docker ps --format '{{.Image}} -------- {{.Names}}'
openshift/origin-haproxy-router -------- k8s_router_router-1-h7q8t_default_32dd802c-2aae-11ea-a260-025000000001_0
openshift/origin-docker-registry -------- k8s_registry_docker-registry-1-6wb4r_default_30efed82-2aae-11ea-a260-025000000001_0
be30b6cce5fa -------- k8s_webconsole_webconsole-564dd67f8c-trpmz_openshift-web-console_41581e8f-2aae-11ea-a260-025000000001_0
openshift/origin-hypershift -------- k8s_operator_openshift-web-console-operator-664b974ff5-4md7w_openshift-core-operators_28658d5b-2aae-11ea-a260-025000000001_0
openshift/origin-hypershift -------- k8s_c_openshift-controller-manager-bwqlm_openshift-controller-manager_26180bcc-2aae-11ea-a260-025000000001_0
openshift/origin-hypershift -------- k8s_apiserver_openshift-apiserver-6tqdq_openshift-apiserver_f84f7692-2aad-11ea-a260-025000000001_0
47dadf9d43b6 -------- k8s_apiservice-cabundle-injector-controller_apiservice-cabundle-injector-8ffbbb6dc-zfd7z_openshift-service-cert-signer_098c0438-2aae-11ea-a260-025000000001_0
47dadf9d43b6 -------- k8s_service-serving-cert-signer-controller_service-serving-cert-signer-668c45d5f-r8r4k_openshift-service-cert-signer_083f559a-2aae-11ea-a260-025000000001_0
openshift/origin-service-serving-cert-signer -------- k8s_operator_openshift-service-cert-signer-operator-6d477f986b-95gcd_openshift-core-operators_f8582dae-2aad-11ea-a260-025000000001_0
openshift/origin-control-plane -------- k8s_kube-dns_kube-dns-cjklm_kube-dns_f854b600-2aad-11ea-a260-025000000001_0
openshift/origin-control-plane -------- k8s_kube-proxy_kube-proxy-b7g7j_kube-proxy_f84f5196-2aad-11ea-a260-025000000001_0
openshift/origin-node:v3.11 -------- origin
```

If you check out the folder we specified while we were issuing the `oc cluster up`, you may have more findings:

```sh
$ tree ${HOME}/openshift.local.clusterup
/Users/brightzheng/openshift.local.clusterup
├── components.json
├── etcd
│   └── member
│       ├── snap
│       │   └── db
│       └── wal
│           ├── 0.tmp
│           └── 0000000000000000-0000000000000000.wal
├── kube-apiserver
│   ├── admin.crt
│   ├── admin.key
│   ├── admin.kubeconfig
│   ├── ca-bundle.crt
│   ├── ca.crt
│   ├── ca.key
│   ├── ca.serial.txt
│   ├── etcd.server.crt
│   ├── etcd.server.key
│   ├── frontproxy-ca.crt
│   ├── frontproxy-ca.key
│   ├── frontproxy-ca.serial.txt
│   ├── master-config.yaml
│   ├── master.etcd-client.crt
│   ├── master.etcd-client.key
│   ├── master.kubelet-client.crt
│   ├── master.kubelet-client.key
│   ├── master.proxy-client.crt
│   ├── master.proxy-client.key
│   ├── master.server.crt
│   ├── master.server.key
│   ├── openshift-aggregator.crt
│   ├── openshift-aggregator.key
│   ├── openshift-master.crt
│   ├── openshift-master.key
│   ├── openshift-master.kubeconfig
│   ├── router.crt
│   ├── router.key
│   ├── router.pem
│   ├── service-signer.crt
│   ├── service-signer.key
│   ├── serviceaccounts.private.key
│   └── serviceaccounts.public.key
├── kubedns
│   ├── ca.crt
│   ├── master-client.crt
│   ├── master-client.key
│   ├── node-client-ca.crt
│   ├── node-config.yaml
│   ├── node-registration.json
│   ├── node.kubeconfig
│   ├── resolv.conf
│   ├── server.crt
│   └── server.key
├── logs
│   ├── centos-imagestreams-001.stderr
│   ├── centos-imagestreams-001.stdout
│   ├── create-kubelet-flags-001.stderr
│   ├── create-kubelet-flags-001.stdout
│   ├── create-master-config-001.stderr
│   ├── create-master-config-001.stdout
│   ├── create-node-config-001.stderr
│   ├── create-node-config-001.stdout
│   ├── install-router-001.stderr
│   ├── install-router-001.stdout
│   ├── kube-dns-001.stderr
│   ├── kube-dns-001.stdout
│   ├── kube-proxy-001.stderr
│   ├── kube-proxy-001.stdout
│   ├── openshift-apiserver-001.stderr
│   ├── openshift-apiserver-001.stdout
│   ├── openshift-controller-manager-001.stderr
│   ├── openshift-controller-manager-001.stdout
│   ├── openshift-image-registry-001.stderr
│   ├── openshift-image-registry-001.stdout
│   ├── openshift-service-cert-signer-operator-001.stderr
│   ├── openshift-service-cert-signer-operator-001.stdout
│   ├── openshift-web-console-operator-001.stderr
│   ├── openshift-web-console-operator-001.stdout
│   ├── sample-templates-cakephp\ quickstart-001.stderr
│   ├── sample-templates-cakephp\ quickstart-001.stdout
│   ├── sample-templates-dancer\ quickstart-001.stderr
│   ├── sample-templates-dancer\ quickstart-001.stdout
│   ├── sample-templates-django\ quickstart-001.stderr
│   ├── sample-templates-django\ quickstart-001.stdout
│   ├── sample-templates-jenkins\ pipeline\ ephemeral-001.stderr
│   ├── sample-templates-jenkins\ pipeline\ ephemeral-001.stdout
│   ├── sample-templates-mariadb-001.stderr
│   ├── sample-templates-mariadb-001.stdout
│   ├── sample-templates-mongodb-001.stderr
│   ├── sample-templates-mongodb-001.stdout
│   ├── sample-templates-mysql-001.stderr
│   ├── sample-templates-mysql-001.stdout
│   ├── sample-templates-nodejs\ quickstart-001.stderr
│   ├── sample-templates-nodejs\ quickstart-001.stdout
│   ├── sample-templates-postgresql-001.stderr
│   ├── sample-templates-postgresql-001.stdout
│   ├── sample-templates-rails\ quickstart-001.stderr
│   ├── sample-templates-rails\ quickstart-001.stdout
│   ├── sample-templates-sample\ pipeline-001.stderr
│   └── sample-templates-sample\ pipeline-001.stdout
├── node
│   ├── ca.crt
│   ├── master-client.crt
│   ├── master-client.key
│   ├── node-client-ca.crt
│   ├── node-config.yaml
│   ├── node-registration.json
│   ├── node.kubeconfig
│   ├── server.crt
│   └── server.key
├── openshift-apiserver
│   ├── admin.crt
│   ├── admin.key
│   ├── admin.kubeconfig
│   ├── ca-bundle.crt
│   ├── ca.crt
│   ├── ca.key
│   ├── ca.serial.txt
│   ├── etcd.server.crt
│   ├── etcd.server.key
│   ├── frontproxy-ca.crt
│   ├── frontproxy-ca.key
│   ├── frontproxy-ca.serial.txt
│   ├── master-config.yaml
│   ├── master.etcd-client.crt
│   ├── master.etcd-client.key
│   ├── master.kubelet-client.crt
│   ├── master.kubelet-client.key
│   ├── master.proxy-client.crt
│   ├── master.proxy-client.key
│   ├── master.server.crt
│   ├── master.server.key
│   ├── openshift-aggregator.crt
│   ├── openshift-aggregator.key
│   ├── openshift-master.crt
│   ├── openshift-master.key
│   ├── openshift-master.kubeconfig
│   ├── service-signer.crt
│   ├── service-signer.key
│   ├── serviceaccounts.private.key
│   └── serviceaccounts.public.key
├── openshift-controller-manager
│   ├── admin.crt
│   ├── admin.key
│   ├── admin.kubeconfig
│   ├── ca-bundle.crt
│   ├── ca.crt
│   ├── ca.key
│   ├── ca.serial.txt
│   ├── etcd.server.crt
│   ├── etcd.server.key
│   ├── frontproxy-ca.crt
│   ├── frontproxy-ca.key
│   ├── frontproxy-ca.serial.txt
│   ├── master-config.yaml
│   ├── master.etcd-client.crt
│   ├── master.etcd-client.key
│   ├── master.kubelet-client.crt
│   ├── master.kubelet-client.key
│   ├── master.proxy-client.crt
│   ├── master.proxy-client.key
│   ├── master.server.crt
│   ├── master.server.key
│   ├── openshift-aggregator.crt
│   ├── openshift-aggregator.key
│   ├── openshift-master.crt
│   ├── openshift-master.key
│   ├── openshift-master.kubeconfig
│   ├── service-signer.crt
│   ├── service-signer.key
│   ├── serviceaccounts.private.key
│   └── serviceaccounts.public.key
├── openshift.local.pv
│   ├── pv0001
│   ├── pv0002
│   ├── <...OMITTED...>
│   ├── pv0100
│   └── registry
└── static-pod-manifests
    ├── apiserver.yaml
    ├── etcd.yaml
    ├── kube-controller-manager.yaml
    └── kube-scheduler.yaml

113 directories, 166 files
```

## Stop the cluster

```sh
oc cluster down
```

## Clean it up

```sh
rm -rf ${HOME}/openshift.local.clusterup
```
