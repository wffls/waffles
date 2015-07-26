source /etc/lsb-release

stdlib.enable_augeas
stdlib.enable_apache

stdlib.apt_key --name augeas --key AE498453 --keyserver keyserver.ubuntu.com
stdlib.apt_source --name augeas --uri http://ppa.launchpad.net/raphink/augeas/ubuntu --distribution trusty --component main
stdlib.apt --package augeas-tools --version latest
stdlib.apt --package git

stdlib.git --state latest --name /usr/src/augeas --source https://github.com/hercules-team/augeas

if [[ $stdlib_resource_change == "true" ]]; then
  stdlib.info "Updating lenses"
  stdlib.capture_error cp "/usr/src/augeas/lenses/*.aug" /usr/share/augeas/lenses/dist/
fi

stdlib.apt --package apache2

apache.section --path "VirtualHost=*:80" --type Directory --name / \
               --file /etc/apache2/sites-enabled/000-default.conf

apache.setting --path "VirtualHost=*:80" \
                --path "Directory=/" \
                --key Require --value valid-user \
                --file /etc/apache2/sites-enabled/000-default.conf
