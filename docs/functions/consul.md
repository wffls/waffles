# Consul Functions

[TOC]

`lib/consul/consul.sh` contains helper functions for the Consul resources

## consul.get_nodes

Returns a list of nodes. Results are stored in `$consul_nodes` hash.

Option `--service`: Optional. Limits results to a set of services.

```shell
consul.get_nodes --service consul

consul_nodes[consul-01]="192.168.1.1"
consul_nodes[consul-02]="192.168.1.2"
consul_nodes[consul-03]="192.168.1.3"
consul_nodes[consul-01|port]="8300"
consul_nodes[consul-02|port]="8300"
consul_nodes[consul-03|port]="8300"
```

## consul.get_services

Returns a list of services in the Consul catalog. Results are stored in `$consul_services array`.

```shell
consul.get_services

consul_services=(consul mysql)
```

## consul.get_kv

Retrieves the value of a key.

```shell
consul.get_kv --key foobar
=> barfoo
```

## consul.set_kv

Sets a value for a key.

```shell
consul.set_kv --key foobar --value barfoo
```

## consul.delete_kv

Deletes a key.

```shell
consul.delete_kv --key foobar
```
