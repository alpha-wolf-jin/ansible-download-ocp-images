# ansible-download-ocp-images

In the OCP disconnected environemnt, we need to downlaod the various operator images.

Here, we will use the ansible to help on this routine and tedious tasks.

Below activites happen on the connected evnronment to create image tar file on the azure VM.

> Please refer to https://github.com/alpha-wolf-jin/mirror-operator for manual process. But here, we use Red Hat mirror-registry instead of docker registry.

**Prepare GIT**
```
# yum install git -y

# git clone https://github.com/alpha-wolf-jin/ansible-download-ocp-images.git
```

```
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/alpha-wolf-jin/ansible-download-ocp-images.git

git config --global credential.helper 'cache --timeout 7200'
git push -u origin main

git add . ; git commit -a -m "update README" ; git push -u origin main
```

**Prepare Ansible package and modules**
```
# 01-prepare.sh
```

# Create Mount Point & Get operator list

The disk `/dev/sdc` is freed and used to create mount point `/opt/registry`

**Detect spare disk**
```
# lsblk
NAME              MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                 8:0    0   64G  0 disk 
├─sda1              8:1    0  500M  0 part /boot
├─sda2              8:2    0   63G  0 part 
│ ├─rootvg-tmplv  253:0    0    2G  0 lvm  /tmp
│ ├─rootvg-usrlv  253:1    0   10G  0 lvm  /usr
│ ├─rootvg-homelv 253:2    0    1G  0 lvm  /home
│ ├─rootvg-varlv  253:3    0    8G  0 lvm  /var
│ └─rootvg-rootlv 253:4    0    2G  0 lvm  /
├─sda14             8:14   0    4M  0 part 
└─sda15             8:15   0  495M  0 part /boot/efi
sdb                 8:16   0   16G  0 disk 
└─sdb1              8:17   0   16G  0 part /mnt
sdc                 8:32   0  512G  0 disk 

```

**Below Paramters with sample values for playbook `02-get-operator-list.yaml`**

- soure_operator_index: redhat-operator-index
- registry_user: sample@redhat.com
- disk_dev: /dev/sdc
- base_home: /opt/registry
- ocp_version: v4.10

You can select one value from below for the param `soure_operator_index`:

- certified-operator-index
- redhat-operator-index
- community-operator-index
- redhat-marketplace-index

**The playbook `02-get-operator-list.yaml` store the operators' names into file `/opt/registry/tmp/<soure_operator_index>_operator_list.json` file.**

```
# ansible-playbook 02-get-operator-list.yaml 
[WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'
What is your password for registry.redhat.io?: 

PLAY [localhost] ****************************************************************************************************************************************************************************

TASK [get full operator list] ***************************************************************************************************************************************************************

# less /opt/registry/tmp/redhat-operator-index_operator_list.json
{
  "name": "3scale-operator"
}
{
  "name": "advanced-cluster-management"
}
...
{
  "name": "quay-operator"
}
...

```

You can identify the operator name and index name from the above operator list generatedby playbook.

For example, we identify below 2 for operator image download:

- redhat-operator-index
- quay-operator

# Install Mirror Quay


**Below Paramters with sample values for playbook ``**

- dest_registry: quay03.example.opentlc.com
- base_home: /opt/registry
- quay_home: "{{ base_home }}/quay"
- quay_install_home: "{{ base_home }}/install"
- mirror_registry_download_url: https://developers.redhat.com/content-gateway/rest/mirror/pub/openshift-v4/clients/mirror-registry/latest/mirror-registry.tar.gz

> `dest_registry` is the target mirror registry server hostname


**Run 03-install_quay.yaml**

```
# cat 03-install_quay.yaml 
---
- hosts: localhost
  connection: local
  become: true
  gather_facts: false

  tasks:

  - name: Install Mirror Quay
    include_role:
      name: install_quay
    vars:
      dest_registry: quay03.example.opentlc.com

# ansible-playbook 03-install_quay.yaml 
```

> Quay is available at https://quay03.example.opentlc.com:8443 with the credentials
> stored in <quay_install_home>/quay_password

# Download Operator Images

```
# cat 04-mirror-operator.yaml 
---
- hosts: localhost
  connection: local
  become: true
  gather_facts: false

  vars_prompt:

    - name: registry_pwd
      prompt: What is your password for registry.redhat.io?

  tasks:

  - name: mirroring-operator
    include_role:
      name: mirroring-operator
    vars:
      operator_list:
      - quay-operator
      registry_user: jinzha1@redhat.com
      dest_registry: quay03.example.opentlc.com
      soure_operator_index: redhat-operator-index
      new_operator_index: storage-operator-index
      mirror_home: /opt/registry/mirror-storage-operator
      mirroring_operator_images: true
      uploading_operator_images: true
      prepare_cmds: false

# ansible-playbook 04-mirror-operator.yaml 
[WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'
What is your password for registry.redhat.io?: 

````

>all images and configureation files are under diretory `<mirror_home>` `/opt/registry/mirror-storage-operator`
> - Images are under `/opt/registry/mirror-storage-operator/v2`
> - Configuration files are under `/opt/registry/mirror-storage-operator/manifests-storage-operator-index/`

# Updating the global cluster pull secret

```
# oc get secret/pull-secret -n openshift-config --template='{{index .data ".dockerconfigjson" | base64decode}}' >/tmp/pull_secret

# oc registry login --registry="helper.example.com:8443" --auth-basic="init:nYZx8hXBo2v1CUc6zsL4T50fQHm3w79l" --to=/tmp/pull_secret

# oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=/tmp/pull_secret
```

# Adding certificate authorities to the cluster

```
# oc create configmap registry-cas -n openshift-config --from-file=helper.example.com..8443=/opt/registry/quay/quay-rootCA/rootCA.pem

# oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-cas"}}}' --type=merge

```

# update cluster for private repo

```
# oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'

# cat /opt/registry/mirror-win-operator/manifests-windows-operator-index/catalogSource.yaml 
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: windows-operator-index
  namespace: openshift-marketplace
spec:
  image: helper.example.com:8443/olm-mirror/windows-operator-index:v4.10
  sourceType: grpc

# oc apply -f catalogSource.yaml

# cat /opt/registry/mirror-win-operator/manifests-windows-operator-index/imageContentSourcePolicy.yaml
---
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  labels:
    operators.openshift.org/catalog: "true"
  name: windows-operator-index-0
spec:
  repositoryDigestMirrors:
  - mirrors:
    - helper.example.com:8443/olm-mirror/openshift4-wincw-windows-machine-config-operator-bundle
    source: registry.redhat.io/openshift4-wincw/windows-machine-config-operator-bundle
  - mirrors:
    - helper.example.com:8443/olm-mirror/openshift4-wincw-windows-machine-config-rhel8-operator
    source: registry.redhat.io/openshift4-wincw/windows-machine-config-rhel8-operator

# oc apply -f imageContentSourcePolicy.yaml

```
