# rabbitmq.ssl_options

## Description

Manages ssl_options settings in a rabbitmq.config file.

## Parameters

* state: The state of the resource. Required. Default: present.
* keyfile: The certificate key. Required.
* certfile: The certificate. Required.
* cacertfile: The ca cert. Optional.
* verify: Verify the peer certificate. Optional.
* fail_if_no_peer_cert: Fail if no peer cert. Optional.
* file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.

## Example

```shell
rabbitmq.ssl_options --certfile /path/to/server/cert.pem --keyfile /path/to/server/key.pem
```

