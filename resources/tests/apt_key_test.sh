apt.key.test.setup() {
  return
}

apt.key.test.create() {
  apt.key --name rabbitmq --remote_keyfile https://www.rabbitmq.com/rabbitmq-release-signing-key.asc
  apt.key --name percona --keyserver keys.gnupg.net --key CD2EFD2A
}

apt.key.test.update() {
  return
}

apt.key.test.delete() {
  apt.key --name rabbitmq --state absent --remote_keyfile https://www.rabbitmq.com/rabbitmq-release-signing-key.asc
  apt.key --name percona --state absent --keyserver keys.gnupg.net --key CD2EFD2A
}

apt.key.test.teardown() {
  return
}
