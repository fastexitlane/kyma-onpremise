# Kyma On Premise Installer
This collection of Ansible roles and playbooks will install [Kyma](kyma-project.io) on freshly provisioned virtual or bare metal machines, including all neccessary infrasstructure components (like Kubernetes) and configurations.

## Components and Configuration
* Kubernetes: one master node, two worker nodes; installation using `kubeadm`; deployments using`kubectl` on the master node
* Persistent Volumes: NFS shares on master node
* Load Balancing / `LoadBalancer` service types: [MetalLB](metallb.universe.tf)
* Container Network Interface: [Flannel](coreos.com/flannel/docs/latest/)

**(!)** Due to the handling of Persistent Volumes, `kubectl` and `kubeadm` usage, only one master node is currently supported.

## Minimal Requirements
* 3 nodes running CentOS 7
* 3 IP adresses attached to the nodes, that `LoadBalancer` service types can be exposed on via MetalLB
* wildcard (sub)domain for cluster pointing to one of the 3 IP adresses
* valid wilcard SSL certificate for wildcard subdomain

## SSH Access
SSH access to these nodes can be done via user/password or public/private key.
The user must be silently privileged, which means that it may uninterruptedly execute `sudo` commands.
This is achieved by a file in `/etc/sudoers.d/${user}` containing the line `${user}  ALL=(ALL)  NOPASSWD: ALL`.

If you have a freshly provisioned virtual or bare metal machine with root user/password access, use the role `ssh-setup` to automatically
* create a `sudo`-enabled user for Ansible
* configure public/private key based SSH access for that user and
* disable user / password login.

What you need to do:
1. configure the usual host access in the `host_vars`
2. add the host fingerprints manually to your local `known_hosts` file (usually `~/.ssh/known_hosts`) as well as to the `.ssh/known_hosts` file in this repo (optional, may be useful for collaboration purposes)
3. create a public private key pair for each host in `.ssh` - the name of the keypair must match `inventory_hostname`
4. configure the keys in the `host_vars` using the parameter `ansible_ssh_private_key_file`, e.g.
    ```yaml
    ansible_ssh_private_key_file: ./.ssh/kyma-master
    ```
5. run the role via command line directly:
    ```bash
    ansible -i inventory all -m import_role -a name=ssh-setup --extra-vars "ansible_user=root ansible_password=rootpassword new_user=ansible new_password=ansiblepassword ansible_ssh_private_key_file= "
    ```
    `--extra-vars` are:
    * `ansible_user`: root user name
    * `ansible_password`: password for root login
    * `new_user`: name of the new user for Ansible
    * `new_password`: UNIX password for the Ansible user
    * `ansible_ssh_private_key_file`: must be left empty to override the already configured private key

## Installation Steps
1. add master and worker node names in respective groups to inventory in `inventory.yaml`
2. add host specific connection configuration files for each inventory host in `host_vars`; relevant parameters may be:
    * `ansible_host`
    * `ansible_user`
    * `ansible_ssh_private_key_file` or
    * `ansible_password`
3. customize configuration parameters in `group_vars/all.yaml`:
    * `metallb_loadbalancing_ips`: IP adresses used by Metal LB
    * `nfs_domain_name`: FQDN that the nfs share is exposed on
    * `kyma_domain_name`: FQDN that kyma will be exposed on
    * `kyma_tls_key`: base64 encoded private key from SSL certificate for Istio Ingress
    * `kyma_tls_cert`: base46 encoeded SSL certificate for Istio Ingress
4. run the `setup` playbook
    ```bash
    ansible-playbook -i inventory setup.yaml
    ```
5. the playbook generates a local file called `kubeconfig` - copy that file to `~/.kube/config`, to get local `kubectl` access to the cluster
6. when the playbook has finished, you can monitor the `kyma-installer` using `./is_installed.sh`
7. if you need `helm` access, run `./configure_helm.sh`

## Resetting the Cluster
Run the `reset` playbook, if you want to tear down the complete Kubernetes cluster.

```bash
    ansible-playbook -i inventory reset.yaml
```

Run the `setup` again, to get a fresh cluster.

**(!)** All persistent files on the NFS share will be deleted during reset. Also, some cleanup steps regarding the container networking will be run on all hosts to avoid issues when recreating the cluster.
