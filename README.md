
# Kubernetes for Development


## The Motivation

There is no limitation while you're provisioning Kubernetes cluster(s) for your development purposes. We're lucky enough to have such a diversified community where offers all kinds of cool tools and well-written tutorials.

So this is really subject to your preference, requirements and resource constraints.

For me, I have set some objectives while thinking the "best way" to have a local Kubernetes cluster for learning, development right in my laptop.

In short, the Kubernetes cluster provisioned:
- MUST be multiple "nodes", e.g. 1 Masters + 3 Workers;
- MUST be easily accessible to each component for necessary tweaking;
- MUST consume bare minimum resources -- I do care about my laptop's battery life;
- MUST be embedded with best practices, as more as possible.


## The Ways

The potential ways might keep growing/evolving along the days.

But as of now, below are what I've tried and considered "great".

| Ranking | Approach | Docs |
| :-----: | -------- | -------- |
| 1       | k3s + k3d | Refer to [README-K3D-K3S.md](README-K3D-K3S.md) |
| 2       | Kubernetes in Docker, aka [kind](https://github.com/kubernetes-sigs/kind) | Refer to [README-KIND.md](README-KIND.md) |
| 3       | Vagrant + VirtualBox | Refer to [README-VAGRANT.md](README-VAGRANT.md) |

If you like the OKD/OpenShift approach, instead of the upstream K8s, you may try these:
- OKD in Docker, refer to [README-OKD-IN-DOCKER.md](README-OKD-IN-DOCKER.md)
- Or [MiniShift](https://www.okd.io/minishift/), which you can find tutorial everywhere.

> Note: all the experiments were on Mac, but working in a Linux env should be very similar.

Enjoy!
