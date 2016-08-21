create() {
  cron.entry --name foobar --cmd ls --minute "*/5" --hour 4
}

update() {
  cron.entry --name foobar --cmd ls --minute "*/5" --hour 5
}

delete() {
  cron.entry --name foobar --state absent --cmd ls --minute "*/5" --hour 5
}
