# Openshift 4 OpenTLC Installation Sandbox Automation

## Description
This project is a basic automation to use the OpenShift Installation sandbox on Red Hat
OpenTLC (internal users only).
The purpose of this tool is not automate the sandbox provising (see AgnosticD for that), but
to provide a simple and fast way to generate a custom install-config.yaml and AWS credential file, 
download the necessary binaries and start the installation.

After the basic cluster installation the automation can install and configure the following features:
- HTPasswd identity provider
- Pipelines Operator
- GitOps Operator
- ACS Operator
- Serverless Operator
- Service Mesh Operator
- OCS Operator

## Prerequisites
Ansible 2.9+ must be installed on the system. Supported systems are Linux and macOS. 

The following additional packages must be installed:
- Python Netaddr to manipulate addressed (`python3-netaddr` on Fedora/RHEL or `netaddr` if installing pip3)
- Python OpenShift to access OpenShift API (`python3-openshift` on Fedora/RHEL or `openshift` if installing with pip3)
- Python Passlib to generate htpasswd files (`python3-passlib` on Fedora/RHEL or `passlib` if installing with pip3)

A future release will automatically handle those dependencies on the different 
platforms.

The following Ansible Collections are required:
- `community.general`, used by core modules
- `ansible.netcommon`, used to apply IP filtering
- `kubernetes.core`, used to test installation results

To install them:
```
$ ansible-galaxy collection install -r requirements.yml
```

### Prerequisites script
The `prerequisites.sh` script provides automates the prequiquisites management on 
**macOS** and **Fedora**. Other distribution improvements are welcome.
The script checks for the `pip` package manager, installs Ansible, the necessary
Python modules and the Ansible Collections.

Simply run the script passing the target distribution as argument:
```
$ ./prerequisites.sh fedora|macos
```

**NOTE**: On macOS the **homebrew** package manager must be already installed to manage extra packages.

## How to use
First, loging to https://labs.opentlc.com to order a new **OpenShift 4 Installation Lab** sandbox under  
```
Services ->  
    Catalog ->  
        OPENTLC OpenShift 4 Labs ->  
            OpenShift 4 Installation Lab
```      


<img src="opentlc_order.png" alt="opentlc" width=1024>
  
  
Click on the **Order** button and complete the request form by submitting the order the lab reason, 
the provisioning AWS region and by accepting terms and conditions. 
  

<img src="opentlc_form.png" alt="form" width=1024>
  


When OpenTLC provisioning is complete, an e-mail will be sent to the requesting user with 
informations about the temporary Sandbox environment.

The important informations in the OpenTLC e-mails appear as follows:
```
Here is some important information about your environment:

Top level domain: .sandboxNNN.opentlc.com

WARNING: with great power comes great responsibility. We monitor usage.
Your AWS programmatic access:
aws_access_key_id = XXXXXXXXXXXXXXXXXXXX
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

SSH Access: ssh <username>@<bastion_url>
SSH password: xxxxxxxxxx
```

**IMPORTANT**: Remember that all OpenTLC labs are time constrained and will be destroyed after a variable amount of time (usually 4/5 working days).
  

### Cluster deployment
After receiving the informations run the cluster deploy playbook locally:
```
$ ansible-playbook install.yaml
```
  
Ansible will prompt for **sudo** password to install the latest `oc` and `openshift-install` 
binaries under the `/usr/local/bin` path.

Users are expected to provide the following mandatory informations in the `user_info.yaml` file in order to complete the installation.
- `base_domain`: the sandbox base domain that will be used to expose APIs and Ingress
- `aws_access_key_id`: the AWS acces key id available in the received e-mail.
- `aws_secret_access_key`: the AWS secret access key available in the received e-mail.
- `pull_secret`: the Red Hat pull secret necessary to pull the cluster images
- `ssh_key`: the public SSH key that will be injected in the nodes
- `install_dir`: the installation directory where install files and logs will be created

After the installation login to the cluster using the provided informations 
in the Ansible output or in the `.openshift_install.log` file in the installation
directory.

Under `install_dir/auth` the installation deploys the `kubeconfig` file.

### Cluster destroy
The OpenTLC labs use AWS sandboxes for demo and training purposes but it is
important to avoid unnecessary compute resource usage, for cost and 
environmental reasons. After finishing using a cluster destroy it using
the follwing command:

```
$ ansible-playbook destroy.yaml
```

The `install_path` variable must be provided (again, in the `user_info.yaml` file, 
to confirm the previously used installation directory.


### Optional Extra Configs
Users can customize cluster installation configs or day two customizations by 
editing the `cluster_config_vars.yaml`. After the base cluster installation is
complete users can choose to create custom users with the HTPasswd identity 
provider or to deploy common extra operators with a simple boolean variable.
Available extra configs, with their predefined values, are:

```
---
# Cluster name
cluster_name: ocp4

# Sizing of master nodes
master_flavor: m5.xlarge

# Sizing of worker nodes.
# This is a minimal size that fits well basic lab and demo environments.
worker_flavor: m5.large

# Number or worker replicas.
worker_replicas: 3

# AWS install region
aws_region: eu-central-1

# Network type. Supported values: OpenShiftSDN, OVNKubernetes
network_type: OpenShiftSDN

# The service network used top allocate service vips. To test Submariner
# multicluster connectivity be sure to use diffrenet CIDRs.
service_network: 172.30.0.0/16

# Enable FIPS mode
fips_enabled: false

## Post Install Configs
# HTPasswd Users. Change passwords before installing.
htpasswd_users:
  developer1: RedHat123!
  developer2: RedHat123!

# Install OpenShift Pipelines Operator
pipelines_operator: true

# Install OpenShift GitOps Operator
gitops_operator: true

# Install ACS Operator
acs_operator: true

# Install Serverless Operator
serverless_operator: false

# Install Service Mesh Operator
# For a successful deploy the operator set worker nodes flavor to m5.xlarge or greater
servicemesh_operator: false

# Install OCS Operator
# The automation will deploy 3 extra (and expensive) m5.2xlarge nodes to run
# the OCS cluster.
ocs_operator: false
```

### Debugging
Sometimes it is useful to repeat the pre and post install tasks for debugging
purposes without having to redeploy the cluster. To do so, skip the install task 
using the `--skip-tags` option:
```
$ ansible-playbook cluster_deploy.yaml --skip-tags install
```

## Maintainers
Gianni Salinetti <gsalinet@redhat.com>  

