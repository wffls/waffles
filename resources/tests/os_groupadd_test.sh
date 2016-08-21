os.groupadd.test.setup() {
  return
}

os.groupadd.test.create() {
  os.groupadd --group jdoe --gid 999
}

os.groupadd.test.update() {
  os.groupadd --group jdoe --gid 998
}

os.groupadd.test.delete() {
  os.groupadd --state absent --group jdoe
}

os.groupadd.test.teardown() {
  return
}
