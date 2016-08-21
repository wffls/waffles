setup() {
  apt.pkg --package ruby1.9.1
}

create() {
  ruby.gem --name tabbit --version 0.0.1
}

update() {
  ruby.gem --name tabbit --version latest
}

delete() {
  ruby.gem --name tabbit --state absent
}

teardown() {
  apt.pkg --package ruby1.9.1 --state absent
}
