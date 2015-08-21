# rabbitmq.config_settings

## Description

Manages settings in a rabbitmq.config file.

## Parameters

* state: The state of the resource. Required. Default: present.
* auth_backends: The auth backend. Optional.
* auth_mechanisms: The auth mechanism. Optional.
* backing_queue_module: The backing queue module. Optional.
* cluster_partition_handling: The cluster_partition_handling setting. Optional.
* collect_statistics: The statistics to collect: none, coarse, fine. Optional.
* collect_statistics_interval: The interval to collect statistics. Optional.
* default_permissions: A CSV list of conf, read, and write default permissions. Optional.
* default_user: The default user. Optional.
* default_user_tags: The default user tags. Optional.
* default_vhost: The default vhost. Optional.
* delegate_count: The delegate count. Optional.
* disk_free_limit_type: The disk free limit type. Either mem_relative or absolute. Optional
* disk_free_limit_value: The disk free liit value. Optional.
* frame_max: The frame max setting. Optional.
* heartbeat: The heartbeat delay in seconds. Optional.
* hipe_compile: Whether or not to enable HiPE. Optional.
* log_levels: Logging settings. Value is in format "connection=info,channel=debug". Optional.
* msg_store_file_size_limit: The message store file size limit. Optional.
* msg_store_index_module: The message store index module. Optional.
* queue_index_max_journal_entries: The queue index max journal entries. Optional.
* tcp_listener_address: The address to listen on for non-SSL connections. Optional.
* tcp_listener_port: The port to listen on for non-SSL connections. Optional.
* vm_memory_high_watermark: The vm_memory_high_watermark setting. Optional.
* ssl_listener_address: The address to listen on for SSL connections. Optional.
* ssl_listener_port: The port to listen on for SSL connections. Optional.
* ssl_keyfile: The certificate key. Optional.
* ssl_certfile: The certificate. Optional.
* ssl_cacertfile: The CA certificate. Optional.
* ssl_verify: Whether to verify the peer certificate. Optional.
* ssl_fail_if_no_peer_cert: Fail if no peer cert. Optional.
* file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.

## Example

```shell
rabbitmq.config_settings --auth_backends PLAIN --auth_mechanisms PLAIN
```

