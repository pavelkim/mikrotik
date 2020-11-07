# MikroTik scripts

## Mikrotik Interface Traffic Usage

Counts rx, tx and total transferred bytes on network interfaces. Stores results in interface's comment and pushes them to InfluxDB.

### Installation

#### Initialise interface comment metadata

You can use WebFig, Winbox or other way to modify the comment. We use CLI:

```bash
/interface ethernet set ether1 comment="{traffic:null}"
/interface wireless set wlan2 comment="{traffic:null}"
```

#### Download the script

```bash
/tool fetch url="https://github.com/pavelkim/mikrotik/releases/latest/download/mikrotik_interface_traffic_usage.rsc" dst-path="scripts/mikrotik_interface_traffic_usage.rsc"
```

#### Set InfluxDB URL

```bash
:global influxDBURL "https://www.myinfluxdb.local/write"
```

#### Configure system scheduler

```bash
/system scheduler add interval=5m name=interface_traffic_usage on-event=":global influxDBURL $influxDBURL; /import scripts/mikrotik_interface_traffic_usage.rsc" policy=read,write,test start-time=startup
```

#### Validate results

Check the scheduler:
```bash 
:put [ /system scheduler get interface_traffic_usage next-run ]
:put [ /system scheduler get interface_traffic_usage run-count ]
```

Check the interface comment:
```bash
:put [/interface ethernet get ether1 comment ]
:put [/interface ethernet get wlan2 comment ]
```

### Example

```bash
[pavelkim@rb-rtcomm0] > /interface ethernet set ether1 comment="{traffic:null}"

[pavelkim@rb-rtcomm0] > :put [/interface ethernet get ether1 comment]
{traffic:null}

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

[pavelkim@rb-rtcomm0] > :put [/interface ethernet get ether1 comment]
{traffic:rx=265624729 tx=2604177885 total=2869802614}
```

## Mikrotik Health Exporter

Installation is similar. Loose these comment modification steps and you're all set.

## Mikrotik RSA Key Provisioning

Upload your public keys somewhere reachable. Modify `keys` variable in the script and run it.
