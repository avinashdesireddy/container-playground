Install Kubernetes
===
###### tags: `draft` `blog` `cheetsheet`

1. Install Container runtime. Kubernetes supports multiple container runtime environments. Here we are installing docker runtime.
    * Installing `docker` runtime on Ubuntu
    ```
    $ sudo apt-get update && apt-get upgrade -y
    $ sudo apt-get install docker.io
    ```
    * Installing `docker` runtime on CentOS
    ```
    $ sudo yum update && yum upgrade -y
    $ sudo yum install -y docker-ce
    ```
    Ref: https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker
    ```
    # Install Docker CE
## Set up the repository
### Install required packages.
yum install yum-utils device-mapper-persistent-data lvm2

### Add Docker repository.
yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

## Install Docker CE.
yum update && yum install \
  containerd.io-1.2.10 \
  docker-ce-19.03.4 \
  docker-ce-cli-19.03.4

## Create /etc/docker directory.
mkdir /etc/docker

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart Docker
systemctl daemon-reload
systemctl restart docker
```

2. Add Kubernetes repository. 
    Ubuntu
    *Edit/Add: /etc/apt/sources.list.d/kubernetes.list* and add the content
    ```
    deb    http://apt.kubernetes.io/    kubernetes-xenial    main
    ```
    Add GPG Key
    ```
    $ curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    
    $ apt-get update
    ```


    CentOS
    *Edit/Add: /etc/yum.repos.d/kubernetes.repo*

cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
    
4. Install the pacakage
    Ubuntu
    ```
    $ apt-get install -y kubeadm=1.14.1-00 kubelet=1.14.1-00 kubectl=1.14.1-00
    ```
    CentOS
    ```
    sudo yum install -y kubelet kubeadm kubectl
    systemctl enable kubelet.service

    ```

    TODO: Elaborate what is 
    * kubeadm: the command to bootstrap the cluster.
    * kubelet: the component that runs on all of the machines in your cluster and does things like starting pods and containers.
    * kubectl: the command line util to talk to your cluster.

## Installing Kube master
5. Delpoy POD network to use for Container Network Interface(CNI)
    * There can be only one pod network per cluster
    * We will use **Calico** here.
    * Calico has more than one configuration file for flexibility with RBAC. 
    * Download the configuration files
        ```
        $ wget https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
        $ wget https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml
        ```
        latest -- https://docs.projectcalico.org/v3.10/manifests/calico.yaml

     * View the content of calico.yaml to identify the IPV4POOL_CIDR   
6. Initialize the master
    ```
    $ kubeadm init \
        --kubernetes-version 1.14.1 \
        --pod-network-cidr 192.168.0.0/16
    ```
    `kubeadmi init` - Creates the cluster
    `--kubernetes-version` - To avoid using newest possible
    `--pod-network-cidr` - IPV4POOL_CIDR IP range found in the CNI config
    
7. As suggested in the instructions of the `kubeadm init` output, run the commands
    ```
    $ mkdir -p $HOME/.kube
    $ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    $ sudo chown $(id -u):$(id -g) $HOME/.kube/config    
    ```
9. Deploy the pod network to the cluster by running the downloaded `rbac-kdd.yaml` and `calico.yaml`
    ```
    $ kubectl apply -f rbac-kdd.yaml
    $ kubectl apply -f calico.yaml
    ```
11. Enable bash auto-completion
    ```
    $ source <(kubectl completion bash)
    $ echo "source <(kubectl completion bash)" >> ~/.bashrc
    ```
13. Verify the master status
    ```
    $ kubectl cluster-info
    ```

## Installing Kube Workers
14. Repeat steps 1-4
15. Run the join command from the output of `kubeadmin init`
    * The join command lasts only 24 hours
    * Create new token
        ```
        $ sudo kubeadm token create ## From master node
        ```
    * Create a Discovery Token CA Cert on the Master. The Hash from the master is used to join the nodes to the cluster securly.
    * *Run on the master node*
        ```
        openssl x509 -pubkey in /etc/kubernetes/pki/ca.cert | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
        ```
16. Use the token and hast to join the cluster from the worker node(s). Use the private IP address and port 6443
    ```
    $ kubeadm join --token <token> master-ip:6443 --discovery-token-ca-cert-hash sha256:<hash>
    ```
17. From the master as kube admin user, verify the nodes
    ```
    $ kubectl get nodes
    $ kubectl describe node <node_name>
    ```
19. 
