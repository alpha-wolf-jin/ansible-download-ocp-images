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

The disk `/dev/sdc` is freed and used to create mount point `/opt/registry`
**Create Mount Point & Get operator list**
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

Below Paramters with sample values:

- soure_operator_index: redhat-operator-index
- registry_user: sample@redhat.com
- disk_dev: /dev/sdc
- base_home: /opt/registry
- ocp_version: v4.10

The value of the param `soure_operator_index` is one of the belows:

- registry.redhat.io/redhat/certified-operator-index
- registry.redhat.io/redhat/redhat-operator-index
- registry.redhat.io/redhat/community-operator-index
- registry.redhat.io/redhat/redhat-marketplace-index
