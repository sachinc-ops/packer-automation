# Role: cron

Creates crontab entries in Linux

## Dependencies

- None

## Role Variables
    
    - cron_config

## Example
```
  --- 
  - hosts: all
    become: true
    roles:
        - role: cron
        cron_config:
        -
            name: test1
            user: root
            job: "php /var/www/test.php"    # Runs in Every Minute
        -
            name: test2
            weekday: 1
            day: 2
            minute: 5
            hour: 1
            user: root
            job: "echo test"        
        -
            name: crontest
            special_time: reboot
            job: "/bin/bash /root/script.sh"
```

`special_time` supported values: `reboot, annually, daily, hourly, monthly, weekly, yearly`

### Author
------

Sachin.C