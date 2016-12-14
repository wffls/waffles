setup() {
  os.file --name /etc/apt/apt.conf.d/02oracle --content "Acquire::http::Proxy { download.oracle.com DIRECT; };"
  apt.key --name java --key EEA14886 --keyserver keyserver.ubuntu.com
  apt.source --name java --uri http://ppa.launchpad.net/webupd8team/java/ubuntu --distribution trusty --component main
}

create() {
  dpkg.debconf --package oracle-java8-installer --question shared/accepted-oracle-license-v1-1 --vtype "select" --value true
}

update() {
  return
}

delete() {
  dpkg.debconf --package oracle-java8-installer --question shared/accepted-oracle-license-v1-1 --vtype "select" --value true --state absent
}

teardown() {
  os.file --name /etc/apt/apt.conf.d/02oracle --content "Acquire::http::Proxy { download.oracle.com DIRECT; };" --state absent
  apt.key --name java --key EEA14886 --keyserver keyserver.ubuntu.com --state absent
  apt.source --name java --uri http://ppa.launchpad.net/webupd8team/java/ubuntu --distribution trusty --component main --state absent
}
