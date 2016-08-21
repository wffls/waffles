os.directory.test.setup() {
  return
}

os.directory.test.create() {
  os.directory --name /opt/foo --mode 0755
  os.directory --name /opt/a/b/c --parent true --mode 0755
}

os.directory.test.update() {
  os.directory --name /opt/foo --mode 0750
}

os.directory.test.delete() {
  os.directory --name /opt/foo --state absent
  os.directory --name /opt/a/b/c --parent true --state absent
}

os.directory.test.teardown() {
  return
}
