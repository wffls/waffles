setup() {
  apt-get update
  apt.pkg --name python-pip
  apt.pkg --name python-virtualenv
}

create() {
  python.virtualenv --name foo
}

update() {
  return
}

delete() {
  python.virtualenv --state absent --name foo
}

teardown() {
  apt.pkg --state absent --name python-pip
  apt.pkg --state absent --name python-virtualenv
}
