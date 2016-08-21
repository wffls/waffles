apt.source.test.setup() {
  return
}

apt.source.test.create() {
  apt.source --name rabbitmq --uri http://www.rabbitmq.com/debian/ --distribution testing --component main --include_src false
}

apt.source.test.update() {
  apt.source --name rabbitmq --uri http://www.rabbitmq.com/debian/ --distribution testing --component main --include_src true
}

apt.source.test.delete() {
  apt.source --name rabbitmq --state absent --uri http://www.rabbitmq.com/debian/ --distribution testing --component main --include_src false
}

apt.source.test.teardown() {
  return
}
