# mikrotik
MikroTik scripts

## interface_traffic_usage (work in progress)

Counts rx+tx bytes on an ethernet interface. Stores data in comment. 
To activate script:

1. Modify the script in order to make it able to send notifications (haha)
1. Add the script to your MikroTik with `name="interface_traffic_usage"`
1. Add an init comment to an ethernet interface:<br>
```[admin@rb381] > /interface ethernet set ether2-master-local comment="Your own text here {traffic:null} or here"```
1. Add a scheduler task:
```[admin@rb381] > /system scheduler add name="interface_traffic_usage_daily" interval="1d" on-event={ /system script run interface_traffic_usage }  policy="read,write,test,policy"```
1. Done
