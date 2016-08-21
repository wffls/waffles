setup() {
  return
}

create() {
  apt.source --name rabbitmq --uri http://www.rabbitmq.com/debian/ --distribution testing --component main --include_src false
}

update() {
  apt.source --name rabbitmq --uri http://www.rabbitmq.com/debian/ --distribution testing --component main --include_src true
}

delete() {
  apt.source --name rabbitmq --state absent --uri http://www.rabbitmq.com/debian/ --distribution testing --component main --include_src false
}

teardown() {
  return
}
