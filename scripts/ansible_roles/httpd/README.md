# Role: httpd

Install and configure http/https in Linux

## Dependencies

- None

## Role Variables
    
 - extra_virtualhost_config

## Example

* simple
 ```
--- 
- hosts: all
   become: true
   roles:
    - role: httpd
```
* Advanced
```
  roles:
    - role: httpd
        extra_virtualhost_config:
        - 
            server_name: subdomain.example.in
            document_root: /var/www/subdomain.example.com/public/
            vhost_specific_config:
                - Alias /v1/ /var/www/demo/public/
        - 
            server_name: example.in
            document_root: /var/www/demo/public/
            server_admin: devops@example.com
            vhost_specific_config:
                - Header set Cache-Control "no-cache, no-store, must-revalidate"
```

### Author
------

Sachin.C