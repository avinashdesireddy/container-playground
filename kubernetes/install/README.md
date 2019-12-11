Install Kubernetes
===
###### tags: `draft` `blog` `cheetsheet`

1. Install Container runtime. Kubernetes supports multiple container runtime environments.
    * Installing `docker` runtime
    ```
    $ sudo apt-get update && apt-get upgrade -y
    $ sudo apt-get install docker.io
    ```
    
    * Installing `rkt` runtime

2. Add Kubernetes repository. 
    *Edit/Add: /etc/apt/sources.list.d/kubernetes.list* and add the content
    ```
    deb    http://apt.kubernetes.io/    kubernetes-xenial    main
    ```
3. Add a GPG key for hte packages and update the repo
    ```
    $ curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    
    $ apt-get update
    ```
    
4. Install the pacakage
    ```
    $ apt-get install -y kubeadm=1.14.1-00 kubelet=1.14.1-00 kubectl=1.14.1-00
    ```

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
