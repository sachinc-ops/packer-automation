# Role: directory-mgt

File, Folder and Symlink management

## Dependencies

- None

## Role Variables
    
    - folder_config

## Example
```
--- 
- hosts: all
  become: true
  roles:
    - role: directory-mgt
      folder_config:
      -
        src: /mnt/drive_1/opt
        dest: /opt/www
        type: link
      -
        path: /opt/www/dir
        perm: '0755'
        owner: apache
        group: apache
        type: directory
      -
        src: /mnt/drive_1/opt/testfile
        dest: /opt/www
        type: file
```


### Author
------

Sachin.C