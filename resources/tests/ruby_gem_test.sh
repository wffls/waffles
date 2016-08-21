ruby.gem.test.setup() {
  apt.pkg --package ruby1.9.1
}

ruby.gem.test.create() {
  ruby.gem --name tabbit --version 0.0.1
}

ruby.gem.test.update() {
  ruby.gem --name tabbit --version latest
}

ruby.gem.test.delete() {
  ruby.gem --name tabbit --state absent
}

ruby.gem.test.teardown() {
  apt.pkg --package ruby1.9.1 --state absent
}
