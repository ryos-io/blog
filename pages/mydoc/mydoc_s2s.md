---
title:  Service-to-Service Authentication
summary: "How to use service credentials in Simulations?"
series: "ACME series"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_s2s.html
folder: mydoc
---

> **_NOTE:_** The feature is from 1.6.0.

In web services environment, it is a common practice that the client services send the service token along with the user tokens to APIs being tested. In this case, one of the tokens is used in `Authorization` header as `Bearer` token whereas the other one is sent in a custom header to backend, e.g `X-Service-Token` or user token `X-User-Token` if the Bearer is the service token. So, the client service might choose to send the user token in `Authorization` header and the service token in a custom header, or vice versa. The test developer can set the type of the bearer with the property: `dev.oauth.bearer` whereas the `dev.oauth.headerName` defines the name of the non-bearer token. The following example demonstrates the service token being as bearer, whereas the `X-User-Token` is being used for the user token:

```
dev.oauth.service.authentication=true
dev.oauth.service.clientId=TestService
dev.oauth.service.clientSecret=123-secret
dev.oauth.service.grantType=authorization_code
dev.oauth.service.clientCode=eyJ4NXUiO12345=
dev.oauth.bearer=service
dev.oauth.headerName=X-User-Token
```

The first line enables the service-to-service authentication. The service will be authenticated with clientId, clientSecret, grantType and the clientCode against authorisation server. As of 1.6.0, the only accepted grant type value is the `authorization_code`. The service token will be sent as bearer while the user token is sent in `X-User-Token`.

> **_WARNING:_** As of 1.6.0, the only accepted grant type value for service-to-service authentication is the `authorization_code`

`dev.oauth.bearer` can take either `service` or `user` pre-defined values. The `service` string literal stands for service token as the `user` is for user token. To enable service-to-service authentication together with user token, use auth() directive on DSL:

```java
Start.dsl()
     .run(http("API Request")
        .header(session -> from(X_REQUEST_ID, "Rhino-" + UUID.randomUUID().toString()))
        .header(X_API_KEY, SimulationConfig.getApiKey())
        .auth()
        .endpoint(FILES_ENDPOINT)
        .get()
        .saveTo("result"))
```

Please note that, the service tokens cannot be sent unattended. They must be accompanied by user tokens in requests. How to deal with test users in simulations, you can refer to [Test Users](https://github.com/ryos-io/Rhino/wiki/Testing-with-Users).