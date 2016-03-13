source /etc/lsb-release

apt.key --name augeas --key AE498453 --keyserver keyserver.ubuntu.com
apt.source --name augeas --uri http://ppa.launchpad.net/raphink/augeas/ubuntu --distribution trusty --component main
apt.pkg --package augeas-tools --version latest
apt.pkg --package git

git.repo --state latest --name /usr/src/augeas --source https://github.com/hercules-team/augeas

if [[ $waffles_state_changed == "true" ]]; then
  log.info "Updating lenses"
  exec.capture_error cp "/usr/src/augeas/lenses/*.aug" /usr/share/augeas/lenses/dist/
fi

apt.pkg --package apache2

apache.section --path "VirtualHost=*:80" --type Directory --name / \
               --file /etc/apache2/sites-enabled/000-default.conf

apache.setting --path "VirtualHost=*:80" \
                --path "Directory=/" \
                --key Require --value valid-user \
                --file /etc/apache2/sites-enabled/000-default.conf
