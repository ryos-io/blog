---
title:  Simulation Configurations
summary: "A Guide how to configure your simulations"
series: "ACME series"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_configuration.html
folder: mydoc
toc: false
---

The Rhino projects require `rhino.properties` test configuration file which contain configuration properties like endpoint configurations, package to scan, etc. and the configuration file _rhino.properties_ must be located in your classpath.

```properties
packageToScan=io.ryos.rhino.sdk

# User Authentication
dev.auth.endpoint=https://auth-endpoint/token
dev.auth.clientId=YourClientId
dev.auth.clientSecret=123-abc
dev.auth.apiKey=YourAPIKey
dev.auth.grantType=password
dev.auth.userSource=classpath:///test_users.csv

# Service Authentication
dev.oauth.service.authentication=true
dev.oauth.service.clientId=TestService
dev.oauth.service.clientSecret=123-secret
dev.oauth.service.grantType=authorization_code
dev.oauth.service.clientCode=eyJ4NXUiO12345=
dev.oauth.bearer=service
dev.oauth.headerName=X-User-Token

# Influx DB Integration
db.influx.url=http://localhost:8086
db.influx.dbName=rhino
db.influx.username=
db.influx.password=

# Grafana Integration
grafana.endpoint=http://localhost:3000
grafana.token="<token with write access obtained from Grafana under Configuration -> API Keys >"

```
Please keep in mind that "auth.*" properties are bound to environments. So, they must be prefixed by environment labels: **dev**, **stage** or **prod** are valid values.

|  Property | Description |
|---|---|
| **packageToScan** | Package name where annotated simulation entities are to be located. Wildcards not supported. The simulation scan is not recursive.  |


### OAuth Configuration

|  Property | Description |
|---|---|
| **{env}.users.source** | file or vault. Vault support is in Beta. |
| **{env}.auth.endpoint**  | Authorization server endpoint |
| **{env}.auth.clientId** |  Client id for user login |
| **{env}.auth.clientSecret** | Client secret for user login  |
| **{env}.auth.apiKey** |  Api key if the service behind the Gateway  |
| **{env}.auth.grantType** | Grant type |
| **{env}.auth.userSource** |  Path to user source. Core SDK currently supports only classpath CSV files e.g classpath:///test_users.csv  |

For service-to-service authentication please refer to [S2S Authentication](http://ryos.io/mydoc_s2s.html) section.

### Influx DB Configuration

|  Property | Description |
|---|---|
| **db.influx.url** |  Influx DB endpoint. |
| **db.influx.dbName** | Metrics db name  |
| **db.influx.username** | DB username |
| **db.influx.password** |  DB Password |

### Grafana Configuration

|  Property | Description |
|---|---|
| **grafana.endpoint** | Grafana endpoint, e.g http://localhost:3000  |
| **grafana.token** | Grafana access token |

### Controlling Resource Utilization 

|  Property | Description |
|---|---|
| **reactive.maxConnections** | Number of connections the HTTP client can handle in reactive mode |
| **runner.parallelisim** | Number of threads in non-reactive mode that a client is allowed to spawn. |

### Http Client Configurations (from 1.6.0) 

|  Property | Description |
|---|---|
| **http.maxConnections** | Number of connections the HTTP client can handle in reactive mode |
| **http.connectTimeout** | Return the maximum time in millisecond an the Http client can wait when connecting to a remote host. |
| **http.readTimeout** | The maximum time in millisecond an Http client can stay idle. |
| **http.handshakeTimeout** | Return the maximum time in millisecond an Http client waits until the client-service handshake is completed. |
| **http.requestTimeout** | Return the maximum time in millisecond an Http client waits until the response is completed. |

### Accessing Configurations

The configurations can be access through SimulationConfig instance in Simulation instances which provides static getter methods. 