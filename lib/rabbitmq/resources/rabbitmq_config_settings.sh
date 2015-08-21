# == Name
#
# rabbitmq.config_settings
#
# === Description
#
# Manages settings in a rabbitmq.config file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * auth_backends: The auth backend. Optional.
# * auth_mechanisms: The auth mechanism. Optional.
# * backing_queue_module: The backing queue module. Optional.
# * cluster_partition_handling: The cluster_partition_handling setting. Optional.
# * collect_statistics: The statistics to collect: none, coarse, fine. Optional.
# * collect_statistics_interval: The interval to collect statistics. Optional.
# * default_permissions: A CSV list of conf, read, and write default permissions. Optional.
# * default_user: The default user. Optional.
# * default_user_tags: The default user tags. Optional.
# * default_vhost: The default vhost. Optional.
# * delegate_count: The delegate count. Optional.
# * disk_free_limit_type: The disk free limit type. Either mem_relative or absolute. Optional
# * disk_free_limit_value: The disk free liit value. Optional.
# * frame_max: The frame max setting. Optional.
# * heartbeat: The heartbeat delay in seconds. Optional.
# * hipe_compile: Whether or not to enable HiPE. Optional.
# * log_levels: Logging settings. Value is in format "connection=info,channel=debug". Optional.
# * msg_store_file_size_limit: The message store file size limit. Optional.
# * msg_store_index_module: The message store index module. Optional.
# * queue_index_max_journal_entries: The queue index max journal entries. Optional.
# * tcp_listener_address: The address to listen on for non-SSL connections. Optional.
# * tcp_listener_port: The port to listen on for non-SSL connections. Optional.
# * vm_memory_high_watermark: The vm_memory_high_watermark setting. Optional.
# * ssl_listener_address: The address to listen on for SSL connections. Optional.
# * ssl_listener_port: The port to listen on for SSL connections. Optional.
# * ssl_keyfile: The certificate key. Optional.
# * ssl_certfile: The certificate. Optional.
# * ssl_cacertfile: The CA certificate. Optional.
# * ssl_verify: Whether to verify the peer certificate. Optional.
# * ssl_fail_if_no_peer_cert: Fail if no peer cert. Optional.
# * file: The file to store the settings in. Optional. Defaults to /etc/rabbitmq/rabbitmq.config.
#
# === Example
#
# ```shell
# rabbitmq.config_settings --auth_backends PLAIN --auth_mechanisms PLAIN
# ```
#
function rabbitmq.config_settings {
  stdlib.subtitle "rabbitmq.config_settings"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n $WAFFLES_EXIT_ON_ERROR ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  stdlib.options.create_option state   "present"
  stdlib.options.create_option file    "/etc/rabbitmq/rabbitmq.config"
  stdlib.options.create_option auth_backends
  stdlib.options.create_option auth_mechanisms
  stdlib.options.create_option backing_queue_module
  stdlib.options.create_option cluster_partition_handling
  stdlib.options.create_option collect_statistics
  stdlib.options.create_option collect_statistics_interval
  stdlib.options.create_option default_permissions
  stdlib.options.create_option default_user
  stdlib.options.create_option default_user_tags
  stdlib.options.create_option default_vhost
  stdlib.options.create_option delegate_count
  stdlib.options.create_option disk_free_limit_type
  stdlib.options.create_option disk_free_limit_value
  stdlib.options.create_option frame_max
  stdlib.options.create_option heartbeat
  stdlib.options.create_option hipe_compile
  stdlib.options.create_option log_levels
  stdlib.options.create_option msg_store_file_size_limit
  stdlib.options.create_option msg_store_index_module
  stdlib.options.create_option queue_index_max_journal_entries
  stdlib.options.create_option tcp_listener_address
  stdlib.options.create_option tcp_listener_port
  stdlib.options.create_option vm_memory_high_watermark
  stdlib.options.create_option ssl_listener_address
  stdlib.options.create_option ssl_listener_port
  stdlib.options.create_option ssl_ssl_keyfile
  stdlib.options.create_option ssl_certfile
  stdlib.options.create_option ssl_cacertfile
  stdlib.options.create_option ssl_verify
stdlib.options.parse_options "$@"

  # Convert everything to an `augeas.generic` option
  if [[ -n "${options[auth_backends]}" ]]; then
    augeas.generic --name "rabbitmq.auth_backends" \
                   --lens Rabbitmq \
                   --file "${options[file]}" \
                   --command "set rabbit/auth_backends/value[0] '${options[auth_backends]}'" \
                   --notif "rabbit/auth_backends/value[. = '${options[auth_backends]}']"
  fi

  if [[ -n "${options[auth_mechanisms]}" ]]; then
    augeas.generic --name "rabbitmq.auth_mechanisms" \
                   --lens Rabbitmq \
                   --file "${options[file]}" \
                   --command "set rabbit/auth_mechanisms/value[0] '${options[auth_mechanisms]}'" \
                   --notif "rabbit/auth_mechanisms/value[. = '${options[auth_mechanisms]}']"
  fi

  if [[ -n "${options[backing_queue_module]}" ]]; then
    augeas.generic --name "rabbitmq.backing_queue_module" \
                   --lens Rabbitmq \
                   --file "${options[file]}" \
                   --command "set rabbit/backing_queue_module[. = '${options[backing_queue_module]}'] '${options[backing_queue_module]}'" \
                   --notif "rabbit/backing_queue_module[. = '${options[backing_queue_module]}']"
  fi

  if [[ -n "${options[cluster_partition_handling]}" ]]; then
    augeas.generic --name "rabbitmq.cluster_partition_handling" \
                   --lens Rabbitmq \
                   --file "${options[file]}" \
                   --command "set rabbit/cluster_partition_handling[. = '${options[cluster_partition_handling]}'] '${options[cluster_partition_handling]}'" \
                   --notif "rabbit/cluster_partition_handling[. = '${options[cluster_partition_handling]}']"
  fi

  if [[ -n "${options[collect_statistics]}" ]]; then
    augeas.generic --name "rabbitmq.collect_statistics" \
                   --lens Rabbitmq \
                   --file "${options[file]}" \
                   --command "set rabbit/collect_statistics[. = '${options[collect_statistics]}'] '${options[collect_statistics]}'" \
                   --notif "rabbit/collect_statistics[. = '${options[collect_statistics]}']"
  fi

  if [[ -n "${options[collect_statistics_interval]}" ]]; then
    augeas.generic --name "rabbitmq.collect_statistics_interval" \
                   --lens Rabbitmq \
                   --file "${options[file]}" \
                   --command "set rabbit/collect_statistics_interval[. = '${options[collect_statistics_interval]}'] '${options[collect_statistics_interval]}'" \
                   --notif "rabbit/collect_statistics_interval[. = '${options[collect_statistics_interval]}']"
  fi

  if [[ -n "${options[default_permissions]}" ]]; then
    stdlib.split "${options[default_permissions]}" ","
    if [[ $(stdlib.array_length __split) == 3 ]]; then
      augeas.generic --name "rabbitmq.default_permissions" \
                     --lens Rabbitmq \
                     --file "${options[file]}" \
                     --command "set rabbit/default_permissions/value[1] '${__split[0]}'" \
                     --command "set rabbit/default_permissions/value[3] '${__split[1]}'" \
                     --command "set rabbit/default_permissions/value[3] '${__split[2]}'"
    fi
  fi

  if [[ -n "${options[default_user]}" ]]; then
    augeas.generic --name "rabbitmq.default_user" \
                   --lens Rabbitmq \
                   --file "${options[file]}" \
                   --command "set rabbit/default_user[. = '${options[default_user]}'] '${options[default_user]}'" \
                   --notif "rabbit/default_user[. = '${options[default_user]}']"
  fi

  if [[ -n "${options[default_user_tags]}" ]]; then
    augeas.generic --name "rabbitmq.default_user_tags" \
                   --lens Rabbitmq \
                   --file "${options[file]}" \
                   --command "set rabbit/default_user_tags[. = '${options[default_user_tags]}']/value[0] '${options[default_user_tags]}'" \
                   --notif "rabbit/default_user_tags/value[. = '${options[default_user_tags]}']"
  fi

  if [[ -n "${options[default_vhost]}" ]]; then
    augeas.generic --name "rabbitmq.default_vhost" \
                   --lens Rabbitmq \
                   --file "${options[file]}" \
                   --command "set rabbit/default_vhost[. = '${options[default_vhost]}'] '${options[default_vhost]}'" \
                   --notif "rabbit/default_vhost[. = '${options[default_vhost]}']"
  fi

  if [[ -n "${options[delegate_count]}" ]]; then
    augeas.generic --name "rabbitmq.delegate_count" \
                   --lens Rabbitmq \
                   --file "${options[file]}" \
                   --command "set rabbit/delegate_count[. = '${options[delegate_count]}'] '${options[delegate_count]}'" \
                   --notif "rabbit/delegate_count[. = '${options[delegate_count]}']"
  fi

  if [[ -n "${options[disk_free_limit_type]}" ]] && [[ -n "${options[disk_free_limit_value]}" ]]; then
    case "${options[limit_type]}" in
      "mem_relative")
        augeas.generic --name "rabbitmq.disk_free_limit" \
                       --lens Rabbitmq \
                       --file "${options[file]}" \
                       --command "set rabbit/disk_free_limit/tuple[0]/value[0] 'mem_relative'" \
                       --command "set rabbit/disk_free_limit/tuple/value[. = 'mem_relative']/../value[last()+1] '${options[disk_free_limit_value]}'"
        ;;
      "absolute")
        augeas.generic --name "rabbitmq.disk_free_limit" \
                       --lens Rabbitmq \
                       --file "${options[file]}" \
                       --command "set /files$_file/rabbit/disk_free_limit '${options[disk_free_limit_value]}'"
        ;;
    esac

  fi

  if [[ -n "${options[frame_max]}" ]]; then
    augeas.generic --name "rabbitmq.frame_max" \
                   --lens Rabbitmq \
                   --file "${options[file]}" \
                   --command "set rabbit/frame_max[. = '${options[frame_max]}'] '${options[frame_max]}'" \
                   --notif "rabbit/frame_max[. = '${options[frame_max]}']"
  fi

  if [[ -n "${options[heartbeat]}" ]]; then
    augeas.generic --name "rabbitmq.heartbeat" \
                   --lens Rabbitmq \
                   --file "${options[file]}" \
                   --command "set rabbit/heartbeat[. = '${options[heartbeat]}'] '${options[heartbeat]}'" \
                   --notif "rabbit/heartbeat[. = '${options[heartbeat]}']"
  fi

  if [[ -n "${options[hipe_compile]}" ]]; then
    augeas.generic --name "rabbitmq.hipe_compile" \
                   --lens Rabbitmq \
                   --file "${options[file]}" \
                   --command "set rabbit/hipe_compile[. = '${options[hipe_compile]}'] '${options[hipe_compile]}'" \
                   --notif "rabbit/hipe_compile[. = '${options[hipe_compile]}']"
  fi

  if [[ -n "${options[log_levels]}" ]]; then
    local _category
    local _level
    stdlib.split "${options[log_levels]}" ","
    for l in "${__split[@]}"; do
      _category="${l%=*}"
      _level="${l##*=}"
      if [[ -n $_category ]] && [[ -n $_level ]]; then
        augeas.generic --name "rabbitmq.log_levels.${_category}" \
                       --lens Rabbitmq \
                       --file "${options[file]}" \
                       --command "set rabbit/log_levels/tuple[0]/value[0] '$_category'" \
                       --command "set rabbit/log_levels/tuple/value[. = '$_category']/../value[0] '$_level'" \
                       --notif "/rabbit/log_levels/tuple/value[. = '$_category']/../value[. = '$_level']"
      fi
    done
  fi

  if [[ -n "${options[msg_store_file_size_limit]}" ]]; then
    augeas.generic --name "rabbitmq.msg_store_file_size_limit" \
                   --lens Rabbitmq \
                   --file "${options[file]}" \
                   --command "set rabbit/msg_store_file_size_limit[. = '${options[msg_store_file_size_limit]}'] '${options[msg_store_file_size_limit]}'" \
                   --notif "rabbit/msg_store_file_size_limit[. = '${options[msg_store_file_size_limit]}']"
  fi

  if [[ -n "${options[msg_store_index_module]}" ]]; then
    augeas.generic --name "rabbitmq.msg_store_index_module" \
                   --lens Rabbitmq \
                   --file "${options[file]}" \
                   --command "set rabbit/msg_store_index_module[. = '${options[msg_store_index_module]}'] '${options[msg_store_index_module]}'" \
                   --notif "rabbit/msg_store_index_module[. = '${options[msg_store_index_module]}']"
  fi

  if [[ -n "${options[queue_index_max_journal_entries]}" ]]; then
    augeas.generic --name "rabbitmq.queue_index_max_journal_entries" \
                   --lens Rabbitmq \
                   --file "${options[file]}" \
                   --command "set rabbit/queue_index_max_journal_entries[. = '${options[queue_index_max_journal_entries]}'] '${options[queue_index_max_journal_entries]}'" \
                   --notif "rabbit/queue_index_max_journal_entries[. = '${options[queue_index_max_journal_entries]}']"
  fi

  if [[ -n "${options[tcp_listener_address]}" ]] && [[ -n "${options[tcp_listener_port]}" ]]; then
    augeas.generic --name "rabbitmq.tcp_listener" \
                   --lens Rabbitmq \
                   --file "${options[file]}" \
                   --command "set rabbit/tcp_listeners/tuple[0]/value[0] '${options[tcp_listener_address]}'" \
                   --command "set rabbit/tcp_listeners/tuple/value[. = '${options[tcp_listener_address]}']/../value[0] '${options[tcp_listener_port]}'" \
                   --notif "/rabbit/tcp_listeners/tuple/value[. = '${options[tcp_listener_address]}']/../value[. = '${options[tcp_listener_port]}']"
  fi

  if [[ -n "${options[vm_memory_high_watermark]}" ]]; then
    augeas.generic --name "rabbitmq.vm_memory_high_watermark" \
                   --lens Rabbitmq \
                   --file "${options[file]}" \
                   --command "set rabbit/vm_memory_high_watermark[. = '${options[vm_memory_high_watermark]}'] '${options[vm_memory_high_watermark]}'" \
                   --notif "rabbit/vm_memory_high_watermark[. = '${options[vm_memory_high_watermark]}']"
  fi

  if [[ -n "${options[ssl_listener_address]}" ]] && [[ -n "${options[ssl_listener_port]}" ]]; then
    augeas.generic --name "rabbitmq.ssl_listener" \
                   --lens Rabbitmq \
                   --file "${options[file]}" \
                   --command "set rabbit/ssl_listeners/tuple[0]/value[0] '${options[ssl_listener_address]}'" \
                   --command "set rabbit/ssl_listeners/tuple/value[. = '${options[ssl_listener_address]}']/../value[0] '${options[ssl_listener_port]}'" \
                   --notif "/rabbit/ssl_listeners/tuple/value[. = '${options[ssl_listener_address]}']/../value[. = '${options[ssl_listener_port]}']"
  fi

  for i in cacertfile certfile keyfile verify fail_if_no_peer_cert; do
    if [[ -n "${options[$i]}" ]]; then
      augeas.generic --name "rabbitmq.ssl_options.$i" \
                     --lens Rabbitmq \
                     --file "${options[file]}" \
                     --command "set rabbit/ssl_options/$i[. = '${options[$i]}'] '${options[$i]}'" \
                     --notif "rabbit/ssl_options/$i[. = '${options[$i]}']"
    fi
  done
}
