cron.entry.test.setup() {
  return
}

cron.entry.test.create() {
  cron.entry --name foobar --cmd ls --minute "*/5" --hour 4
}

cron.entry.test.update() {
  cron.entry --name foobar --cmd ls --minute "*/5" --hour 5
}

cron.entry.test.delete() {
  cron.entry --name foobar --state absent --cmd ls --minute "*/5" --hour 5
}

cron.entry.test.teardown() {
  return
}
