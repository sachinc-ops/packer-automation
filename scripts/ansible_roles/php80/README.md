
# Role: php80

This role installs php 8.0 from amazon-linux-extras repo

## Dependencies

- NA

## Role Variables
    
    - php_extentions_extra

## Example
### Simple
```
--- 
- hosts: all
   become: true
   roles:
    - php80
```
### Advanced
```
  roles:
    - role: php80
      php_extentions_extra:
        - php-memcached
        - php-zip

```

### Author
------

Sachin.C