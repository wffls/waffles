source /etc/lsb-release

stdlib.enable_augeas

stdlib.apt_key --name augeas --key AE498453 --keyserver keyserver.ubuntu.com
stdlib.apt_source --name augeas --uri http://ppa.launchpad.net/raphink/augeas/ubuntu --distribution trusty --component main
stdlib.apt --package augeas-tools --version latest
stdlib.apt --package git

stdlib.git --state latest --name /usr/src/augeas --source https://github.com/hercules-team/augeas

if [[ $stdlib_resource_change == "true" ]]; then
  stdlib.info "Updating lenses"
  stdlib.capture_error cp "/usr/src/augeas/lenses/*.aug" /usr/share/augeas/lenses/dist/
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

augeas.aptconf --setting APT::Periodic::Update-Package-Lists --value 1 --file /etc/apt/apt.conf.d/20auto-upgrades
augeas.aptconf --setting APT::Periodic::Unattended-Upgrade --value 1 --file /etc/apt/apt.conf.d/20auto-upgrades

augeas.cron --name metrics --minute "*/5" --cmd /usr/local/bin/collect_metrics.sh

augeas.file_line --name foo --file /root/foo.txt --line "Hello, World!"

augeas.host --name example.com --ip 192.168.1.1 --aliases www,db --file /root/hosts

augeas.ini --section DEFAULT --option foo --value bar --file /root/ini

augeas.json_dict --file /root/foo.json --path / --key foo --value _array
augeas.json_dict --file /root/foo.json --path / --key bar --value _dict
augeas.json_dict --file /root/foo.json --path / --key baz --value "bar"
augeas.json_array --file /root/foo.json --path / --key foo --value 1 --value 2 --value 3

augeas.mail_alias --account root --destination /dev/null

augeas.shellvar --key foo --value bar --file /root/vars

augeas.ssh_authorized_key --name jdoe --key "AAAAB3NzaC1yc2EAAAADAQABAAABAQDkyN3CECzDtVKBj6MEx9P0LMMxkxgCYruFWhqO5+eRKlXdyIDpprtknxxsm2VcXj2kiApVS4d9MJeMZELiUOM7bEsSFiF255Uda8CJoNN3QCobUJtx9LaKan0mUDykbCBoy0ZKBGW5sTx9OOxJV3P/oMkwXKRD3fJBo1PCGZLMVplclXAHaYrLw1VkKM9hnOFAqHxXYFUT53Zm24CPxAZOq98xUXKBTNw+Jkd6+wxdgaqkdGU++vLhU3QIdp60AztleJL/OJJZ6i3a21boeSstFoSChuLBhwIqeIRyJUH1OP77SmrzWaUeXn9QP9WMX44RR6BrhdZFBMsTVozkRn1d" --type ssh-rsa --comment "jdoe@foobar" --file "/root/authorized_keys"
