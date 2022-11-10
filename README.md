# MikroTik scripts

## Mikrotik Interface Traffic Usage

Counts rx, tx and total transferred bytes on network interfaces and pushes metrics into InfluxDB.
The script stores the last taken mesurements in files named "$resultsFilenameBase_$interfaceName"

List of generated metrics:
```
monitoring_traffic_rx
monitoring_traffic_tx
```

### Installation

#### Download the script

```bash
/tool fetch url="https://github.com/pavelkim/mikrotik/releases/latest/download/mikrotik_interface_traffic_usage.rsc" dst-path="scripts/mikrotik_interface_traffic_usage.rsc"
```

#### Set your InfluxDB write URL

```bash
:global influxDBURL "https://www.myinfluxdb.local/write"
```

#### Configure system scheduler

Add the actual schedule:
```bash
/system scheduler add interval=5m name=interface_traffic_usage on-event=":global influxDBURL $influxDBURL; /import scripts/mikrotik_interface_traffic_usage.rsc" policy=read,write,test start-time=startup
```

Check the scheduler:
```bash 
:put [ /system scheduler get interface_traffic_usage next-run ]
:put [ /system scheduler get interface_traffic_usage run-count ]
```

### Example

```bash

[pavelkim@rb-rtcomm0] > /tool fetch url="https://github.com/pavelkim/mikrotik/releases/latest/download/mikrotik_interface_traffic_usage.rsc" dst-path="scripts/mikrotik_interface_traffic_usage.rsc"
      status: finished
  downloaded: 6KiBC-z pause]
       total: 6KiB
    duration: 0s

[pavelkim@rb-rtcomm0] > :global influxDBURL "https://victoriametrics.example.com/write"

[pavelkim@rb-rtcomm0] > :put message="$influxDBURL"
https://victoriametrics.example.com/write

[pavelkim@rb-rtcomm0] > /system scheduler add interval=5m name=interface_traffic_usage on-event=":global influxDBURL $influxDBURL; /import scripts/mikrotik_interface_traffic_usage.rsc" policy=read,write,test start-time=startup

[pavelkim@rb-rtcomm0] > /system scheduler pr
Flags: X - disabled 
 #   NAME                   START-DATE  START-TIME                 INTERVAL             ON-EVENT                  RUN-COUNT
 0   interface_traffic_u...             startup                    5m                   /import scripts/mikro...          0

[pavelkim@rb-rtcomm0] > :put [ /system scheduler get interface_traffic_usage next-run ]
06:28:02

[pavelkim@rb-rtcomm0] > :put [ /system scheduler get interface_traffic_usage run-count ]
2
```

## Mikrotik Health Exporter

Reads CPU, disk and memory metrics, and pushes them into InfluxDB.

List of generated metrics:
```
monitoring_deviceTemperature
monitoring_deviceMemFree
monitoring_deviceMemTotal
monitoring_deviceDiskFree
monitoring_deviceDiskTotal
monitoring_deviceDiskBadBlocks
monitoring_deviceDiskWriteSectSinceReboot
monitoring_deviceDiskWriteSectTotal
monitoring_deviceCPULoad
```

### Installation

#### Download the script

```bash
/tool fetch url="https://github.com/pavelkim/mikrotik/releases/latest/download/mikrotik_health_exporter.rsc" dst-path="scripts/mikrotik_health_exporter.rsc"
```

#### Set your InfluxDB write URL

```bash
:global influxDBURL "https://www.myinfluxdb.local/write"
```

#### Configure system scheduler

Add the actual schedule:
```bash
/system scheduler add interval=5m name=health_exporter.rsc on-event=":global influxDBURL $influxDBURL; /import scripts/mikrotik_health_exporter.rsc" policy=read,write,test start-time=startup
```

Check the scheduler:
```bash 
:put [ /system scheduler get health_exporter next-run ]
:put [ /system scheduler get health_exporter run-count ]
```

### Example

```bash

[pavelkim@rb-rtcomm0] > /tool fetch url="https://github.com/pavelkim/mikrotik/releases/latest/download/mikrotik_health_exporter.rsc" dst-path="scripts/mikrotik_health_exporter.rsc"
      status: finished
  downloaded: 6KiBC-z pause]
       total: 6KiB
    duration: 0s

[pavelkim@rb-rtcomm0] > :global influxDBURL "https://victoriametrics.example.com/write"

[pavelkim@rb-rtcomm0] > :put message="$influxDBURL"
https://victoriametrics.example.com/write

[pavelkim@rb-rtcomm0] > /system scheduler add interval=5m name=health_exporter on-event=":global influxDBURL $influxDBURL; /import scripts/mikrotik_health_exporter.rsc" policy=read,write,test start-time=startup

[pavelkim@rb-rtcomm0] > /system scheduler pr
Flags: X - disabled 
 #   NAME                   START-DATE  START-TIME                 INTERVAL             ON-EVENT                  RUN-COUNT
 0   interface_traffic_u...             startup                    5m                   /import scripts/mikro...          0

[pavelkim@rb-rtcomm0] > :put [ /system scheduler get health_exporter next-run ]
06:28:02

[pavelkim@rb-rtcomm0] > :put [ /system scheduler get health_exporter run-count ]
2
```

## Mikrotik RSA Key Provisioning

Provisions public RSA keys to your mikrotik router.

### Prepare your keys

Example of how to generate an RSA key pair:

```bash
ssh-keygen -t rsa -N "passphrase" -f ~/.ssh/id_rsa
```

```
cat ~/.ssh/id_rsa.pub
```

### Share public RSA keys

Use pastebin or something similar to make your public RSA key downloadable, so the script could reach it from your router.

Example in pastebin: https://pastebin.com/raw/w69viks1

### Define variables

Define key URLs for each user you need to set up:
```mikrotik
:global keys { "username"=( "https://pastebin.com/raw/w69viks1", "https://pastebin.com/raw/636SeR6d" ) }
```

### Download and execute

Download the script:
```
/tool fetch url="https://github.com/pavelkim/mikrotik/releases/latest/download/mikrotik_install_rsa_keys.rsc" dst-path="scripts/mikrotik_install_rsa_keys.rsc"
```

Run the script to provision the keys for the users:
```
/import scripts/mikrotik_install_rsa_keys.rsc
```

## Support

Please, use Github issues for commuication.
