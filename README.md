# ansible-download-ocp-images

**Prepare GIT**
```
# yum install git -y

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
