setup() {
  return
}

create() {
  apt.key --name rabbitmq --remote_keyfile https://www.rabbitmq.com/rabbitmq-release-signing-key.asc
  apt.key --name percona --keyserver keys.gnupg.net --key CD2EFD2A
}

update() {
  return
}

delete() {
  apt.key --name rabbitmq --state absent --remote_keyfile https://www.rabbitmq.com/rabbitmq-release-signing-key.asc
  apt.key --name percona --state absent --keyserver keys.gnupg.net --key CD2EFD2A
}

teardown() {
  return
}
