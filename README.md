# GDA-Websocket
GDA Websocket Feed for cryptocurrencies

## Process flow chart
![plot](./process_flow_chart.png)

## Port Mapping
| Element     | Port Number |
|-------------|-------------|
| Tickerplant | 5000        |
| HDB         | 5002        |
| RDB         | 5008        |
| RTE         | 5112        |
| CTP         | 5110        |
| FH          | 5111        |
| GW          | 5005        |

## Implementation into AWS

### Git

```git
git clone https://github.com/sbruce01/GDA-Websocket.git
```

Double check the startup script to see if the directories work correctly (Redhat vs Ubuntu slight differences)

### Developer

1. Put developer zip into the s3 bucket 
2. Unzip developer.zip
3. Install developer through `./install.sh`
4. Check Q definition ensuring commandline arguments are picked up (Can test with `q -p 5000` and `system"p"`)
5. Check the port defined in the `config.profile` is what's desired
6. Run developer:
```
source /path-to-install-dir/config/config.profile
q /path-to-install-dir/launcher.q_
```
7. Connect to developer using `IP`:`PORT`. N.B. `IP` will either be the Elastic IP Address or Private IP Address