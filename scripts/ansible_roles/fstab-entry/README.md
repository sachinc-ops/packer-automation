# Role: fstab-entry

Add fstab entries

## Dependencies

- None

## Role Variables
    
    - entries

## Example
```
--- 
- hosts: all
  become: true
  roles:
    - role: fstab-entry
      entries:
      -
        src: fs-12345.efs.us-east-1.amazonaws.com:/
        path: /efs-mount
        fstype: nfs4
        opts: nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2  
      -
        src: /dev/xvdf1
        path: /mnt/www
        fstype: ext4
        opts: noatime
```


### Author
------

Sachin C