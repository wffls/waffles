# Core Libraries and Functions
source "$WAFFLES_DIR/lib/stdlib/catalog.sh"
source "$WAFFLES_DIR/lib/stdlib/options.sh"
source "$WAFFLES_DIR/lib/stdlib/resource.sh"
source "$WAFFLES_DIR/lib/stdlib/system.sh"
source "$WAFFLES_DIR/lib/stdlib/template.sh"

# Standard Library of Resources
source "$WAFFLES_DIR/lib/stdlib/resources/apt.sh"
source "$WAFFLES_DIR/lib/stdlib/resources/apt_key.sh"
source "$WAFFLES_DIR/lib/stdlib/resources/apt_ppa.sh"
source "$WAFFLES_DIR/lib/stdlib/resources/apt_source.sh"
source "$WAFFLES_DIR/lib/stdlib/resources/cron.sh"
source "$WAFFLES_DIR/lib/stdlib/resources/debconf.sh"
source "$WAFFLES_DIR/lib/stdlib/resources/directory.sh"
source "$WAFFLES_DIR/lib/stdlib/resources/file.sh"
source "$WAFFLES_DIR/lib/stdlib/resources/file_line.sh"
source "$WAFFLES_DIR/lib/stdlib/resources/git.sh"
source "$WAFFLES_DIR/lib/stdlib/resources/groupadd.sh"
source "$WAFFLES_DIR/lib/stdlib/resources/ini.sh"
source "$WAFFLES_DIR/lib/stdlib/resources/iptables_rule.sh"
source "$WAFFLES_DIR/lib/stdlib/resources/ip6tables_rule.sh"
source "$WAFFLES_DIR/lib/stdlib/resources/sudo_cmd.sh"
source "$WAFFLES_DIR/lib/stdlib/resources/sysvinit.sh"
source "$WAFFLES_DIR/lib/stdlib/resources/upstart.sh"
source "$WAFFLES_DIR/lib/stdlib/resources/useradd.sh"

# Augeas-based Resources and Functions
function stdlib.enable_augeas {
  source "$WAFFLES_DIR/lib/augeas/augeas.sh"
  source "$WAFFLES_DIR/lib/augeas/resources/augeas_aptconf.sh"
  source "$WAFFLES_DIR/lib/augeas/resources/augeas_cron.sh"
  source "$WAFFLES_DIR/lib/augeas/resources/augeas_file_line.sh"
  source "$WAFFLES_DIR/lib/augeas/resources/augeas_generic.sh"
  source "$WAFFLES_DIR/lib/augeas/resources/augeas_host.sh"
  source "$WAFFLES_DIR/lib/augeas/resources/augeas_ini.sh"
  source "$WAFFLES_DIR/lib/augeas/resources/augeas_json_array.sh"
  source "$WAFFLES_DIR/lib/augeas/resources/augeas_json_dict.sh"
  source "$WAFFLES_DIR/lib/augeas/resources/augeas_mail_alias.sh"
  source "$WAFFLES_DIR/lib/augeas/resources/augeas_shellvar.sh"
  source "$WAFFLES_DIR/lib/augeas/resources/augeas_ssh_authorized_key.sh"
}

# MySQL-based Resources and Functions
function stdlib.enable_mysql {
  source "$WAFFLES_DIR/lib/mysql/mysql.sh"
  source "$WAFFLES_DIR/lib/mysql/resources/mysql_database.sh"
  source "$WAFFLES_DIR/lib/mysql/resources/mysql_grant.sh"
  source "$WAFFLES_DIR/lib/mysql/resources/mysql_user.sh"
}

# RabbitMQ-based Resources and Functions
function stdlib.enable_rabbitmq {
  source "$WAFFLES_DIR/lib/rabbitmq/rabbitmq.sh"
  source "$WAFFLES_DIR/lib/rabbitmq/resources/rabbitmq_cluster_nodes.sh"
  source "$WAFFLES_DIR/lib/rabbitmq/resources/rabbitmq_config_settings.sh"
  source "$WAFFLES_DIR/lib/rabbitmq/resources/rabbitmq_policy.sh"
  source "$WAFFLES_DIR/lib/rabbitmq/resources/rabbitmq_user_permissions.sh"
  source "$WAFFLES_DIR/lib/rabbitmq/resources/rabbitmq_user.sh"
  source "$WAFFLES_DIR/lib/rabbitmq/resources/rabbitmq_vhost.sh"
}

# Nginx-based Resources and Functions
function stdlib.enable_nginx {
  source "$WAFFLES_DIR/lib/nginx/resources/nginx_events.sh"
  source "$WAFFLES_DIR/lib/nginx/resources/nginx_global.sh"
  source "$WAFFLES_DIR/lib/nginx/resources/nginx_http.sh"
  source "$WAFFLES_DIR/lib/nginx/resources/nginx_if.sh"
  source "$WAFFLES_DIR/lib/nginx/resources/nginx_location.sh"
  source "$WAFFLES_DIR/lib/nginx/resources/nginx_map.sh"
  source "$WAFFLES_DIR/lib/nginx/resources/nginx_server.sh"
  source "$WAFFLES_DIR/lib/nginx/resources/nginx_upstream.sh"
}

# Apache-based Resources and Functions
function stdlib.enable_apache {
  source "$WAFFLES_DIR/lib/apache/resources/apache_section.sh"
  source "$WAFFLES_DIR/lib/apache/resources/apache_setting.sh"
}

# Keepalived-based Resources and Functions
function stdlib.enable_keepalived {
  source "$WAFFLES_DIR/lib/keepalived/resources/keepalived_global_defs.sh"
  source "$WAFFLES_DIR/lib/keepalived/resources/keepalived_vrrp_instance.sh"
  source "$WAFFLES_DIR/lib/keepalived/resources/keepalived_vrrp_script.sh"
  source "$WAFFLES_DIR/lib/keepalived/resources/keepalived_vrrp_sync_group.sh"
}

# Consul-based Resources and Functions
function stdlib.enable_consul {
  source "$WAFFLES_DIR/lib/consul/consul.sh"
  source "$WAFFLES_DIR/lib/consul/resources/consul_check.sh"
  source "$WAFFLES_DIR/lib/consul/resources/consul_service.sh"
  source "$WAFFLES_DIR/lib/consul/resources/consul_template.sh"
  source "$WAFFLES_DIR/lib/consul/resources/consul_watch.sh"
}

# Python-based Resources and Functions
function stdlib.enable_python {
  source "$WAFFLES_DIR/lib/python/resources/python_pip.sh"
  source "$WAFFLES_DIR/lib/python/resources/python_virtualenv.sh"
}
