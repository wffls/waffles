#!/bin/bash
source /opt/waffles/init.sh
source /etc/lsb-release

apt.pkg --name git
apt.pkg --name ruby2.0
os.symlink --name /usr/bin/ruby --target /usr/bin/ruby2.0 --overwrite true
os.symlink --name /usr/bin/gem --target /usr/bin/gem2.0 --overwrite true

apt.key --name docker --key 58118E89F3A912897C070ADBF76221572C52609D --keyserver hkp://p80.pool.sks-keyservers.net:80
apt.source --name docker --uri https://apt.dockerproject.org/repo --distribution ubuntu-$DISTRIB_CODENAME --component main
apt.pkg --name docker-engine

ruby.gem --name test-kitchen
ruby.gem --name kitchen-docker
ruby.gem --name busser-bash
ruby.gem --name busser-bats
ruby.gem --name busser-serverspec

git.repo --name /root/.waffles --source https://github.com/wffls/waffles
