setup() {
  apt-get update
  apt.pkg --name python-pip
}

create() {
  python.pip --name minilanguage --version 0.3.0
}

update() {
  return
}

delete() {
  python.pip --state absent --name minilanguage --version 0.3.0
}

teardown() {
  apt.pkg --state absent --name python-pip
}
