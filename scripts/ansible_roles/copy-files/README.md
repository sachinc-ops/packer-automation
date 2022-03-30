   # Role: copy_files

Copies files and folders from local to remote

## Dependencies
- None

## Role Variables
    - files

## Usage
IMPORTANT: Source files/folders should be placed inside `files` folder where the `ansible.yaml` file exists.

Eg: `projects/dev/demo_project/app/files/testfile.sh`

```
--- 
- hosts: all
  become: true
  roles:
    - role: copy_files
      files:
        -
         src: testfile.sh
         dest: /var/www/
        - 
         src: testfolder
         dest: /var/www/
```


### Author
------

Sachin.C