# This will fail until patches to the RabbitMQ Augeas lens are merged.

source /etc/lsb-release

stdlib.enable_augeas
stdlib.enable_rabbitmq

stdlib.apt_key --name augeas --key AE498453 --keyserver keyserver.ubuntu.com
stdlib.apt_source --name augeas --uri http://ppa.launchpad.net/raphink/augeas/ubuntu --distribution trusty --component main
stdlib.apt --package augeas-tools --version latest
stdlib.apt --package git

stdlib.git --state latest --name /usr/src/augeas --source https://github.com/hercules-team/augeas

if [[ $stdlib_resource_change == "true" ]]; then
  stdlib.info "Updating lenses"
  stdlib.capture_error cp "/usr/src/augeas/lenses/*.aug" /usr/share/augeas/lenses/dist/
fi

stdlib.apt_key --name rabbitmq --key 056E8E56 --remote_keyfile https://www.rabbitmq.com/rabbitmq-signing-key-public.asc
stdlib.apt_source --name rabbitmq --uri http://www.rabbitmq.com/debian/ --distribution testing --component main --include_src false

stdlib.apt --package rabbitmq-server
stdlib.sysvinit --name rabbitmq-server
rabbitmq.user --state absent --user guest

rabbitmq.auth_backend --backend PLAIN
rabbitmq.auth_mechanism --mechanism PLAI
rabbitmq.default_user --user guest --pass guest
rabbitmq.default_vhost --vhost /
rabbitmq.disk_free_limit --limit_type mem_relative --value 1.0
rabbitmq.tcp_listeners --address 127.0.0.1 --port 5672
rabbitmq.tcp_listeners --address ::1 --port 5672
rabbitmq.log_levels --category connection --level debug
rabbitmq.log_levels --category channel --level error
