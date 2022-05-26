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

## REST API

### Use

The `GW` process hosts a REST API endpoint which enables users to query the RDB and HDB via GET requests. The endpoint sits at `/getData` which if called without filters returns orders data from all instruments and exchanges over the past minute. The included filters are:

| Filter | Type            | Example                       | Available Values         |
|--------|-----------------|-------------------------------|--------------------------|
| tbls   | Atomic symbol   | order                         | order, trade             |
| sd     | Atomic timestamp | 2022.05.20D06:13:42.000000000 | N/A                      |
| ed     | Atomic timestamp | 2022.05.20D06:16:42.000000000 | N/A                      |
| ids    | Symbol list     | BTCUSD,ABC                    | BTCUSD, BTCUSDT          |
| exc    | Symbol list     | coinbase,bybit                | coinbase, bybit, binance |

### Implementation

For the rest functionality, if you are only exposing an endpoint, the `.com_kx_rest.init`, `.com_kx_rest.register` and `.com_kx_rest.data` API are the only necessary APIs

The documentation for each of these can be found [at this address](https://code.kx.com/insights/1.0/core/rest-server/api_reference.html)

An example of setting up a register exists in a [whitepaper](https://code.kx.com/insights/1.0/core/rest-server/appendix/queryserver.html)

Within our recent implementation there is a fairly straightforward example of creating a register. This is found in [this element of the Git Repo](https://github.com/sbruce01/GDA-Websocket/blob/main/tick/gw.q)

The requirement for this is to load in the rest.q_ binary file which is included in KxCloudEdition after install within the lib folder:
```
lib/qce-20220310180901/rest.q_
```

### Examples

```bash
# Get data from all exchanges and instruments for the past minute
curl 'localhost:5005/getData'
# Get data from a specified start time to the current time 
curl 'localhost:5005/getData?sd=2022.05.20D04:42:40.000000000'
# Get data for a specified window of time 
curl 'localhost:5005/getData?sd=2022.05.20D04:42:40.000000000&ed=2022.05.20D04:43:40.000000000'
# Get data for a specific exchange (from a specified start time)
curl 'localhost:5005/getData?sd=2022.05.20D04:42:40.000000000&exc=binance'
# Get data for a specific instrument (from a specified start time)
curl 'localhost:5005/getData?sd=2022.05.20D04:42:40.000000000&ids=BTCUSD'
```



## KX Websocket End point subscription
Connect your websocket client to ws://localhost:5110

A basic command is sent in the following format:
```json
{"type": "sub", "tables": `[<tableName>]`,"syms":`[<SubscriptionSymbol>]`}
```

You may subscribe to multiple tables at a time by sending an array of subscription table names.

Please see examples in the ctp_ws.q 

## Implementation into AWS

### KxCloudEdition Steps

Prerequisites: `curl`, `unzip`, `rlwrap`

Pull down the package

```console
curl https://nexus.dl.kx.com/repository/kx-insights-packages/KxCloudEdition/3.0.0/KxCloudEdition-3.0.0.tgz --user sstantoncook -o KxCloudEdition-3.0.0.tgz
```

Unzip the package

(The following is assuming a current directory of KxCloudEdition-* folder)

Run the `qce-install.sh` file which sits in `./code/kdb`

Add `../bin` to PATH and QHOME=`../lib/qce-YYYY.../` to aliases. Example of this being done in the ~/.bashrc script:

```bash
# Adding bin to Path for Q (KX Developer)
export PATH="/data/KX_GDA/bin:$PATH"
# Adding QHOME
export QHOME=/data/KX_GDA/lib/qce-20220310180901
```

Add to the bin folder the file `q` with the definition:

```bash
export QHOME=/data/KX_GDA/lib/qce-20220310180901
rlwrap $QHOME/l64/q $@
```

This explicit definition within the q script makes it easier for multiple users to call Q not just those who's profile is ~/.bashrc

### Git Repository

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
