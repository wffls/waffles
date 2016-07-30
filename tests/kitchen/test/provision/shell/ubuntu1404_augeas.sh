#!/bin/bash
source /root/.waffles/init.sh
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

if [[ ! -f /root/hosts ]]; then
  cp /etc/hosts /root/hosts
fi

augeas.generic --name test --lens Hosts --file /root/hosts \
  --command "set *[canonical = 'localhost'][1]/ipaddr '10.3.3.27'" \
  --onlyif "*/ipaddr[. = '127.0.0.1']/../canonical result include 'localhost'"

augeas.generic --name test2 --lens Hosts --file /root/hosts \
  --command "set 0/ipaddr '8.8.8.8'" \
  --command "set 0/canonical 'google.com'" \
  --onlyif "*/ipaddr[. = '8.8.8.8'] result not_include '8.8.8.8'"

augeas.generic --name test3 --lens Hosts --file /root/hosts \
  --command "set 0/ipaddr '1.1.1.1'" \
  --command "set 0/canonical 'foobar.com'" \
  --onlyif "*/ipaddr[. = '1.1.1.1'] path not_include 'ipaddr'"

augeas.generic --name test4 --lens Hosts --file /root/hosts \
  --command "set 0/ipaddr '2.2.2.2'" \
  --command "set 0/canonical 'barfoo.com'" \
  --onlyif "*/ipaddr[. = '2.2.2.2'] size == 0"

augeas.generic --name test5 --lens Hosts --file /root/hosts \
  --command "set 0/ipaddr '3.3.3.3'" \
  --command "set 0/canonical 'bazbar.com'" \
  --onlyif "*/ipaddr[. = '3.3.3.3'] size -lt 1"
