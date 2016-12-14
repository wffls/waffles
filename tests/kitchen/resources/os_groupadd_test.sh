setup() {
  return
}

create() {
  os.groupadd --group jdoe --gid 999
}

update() {
  os.groupadd --group jdoe --gid 998
}

delete() {
  os.groupadd --state absent --group jdoe
}

teardown() {
  return
}
