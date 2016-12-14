setup() {
  return
}

create() {
  os.directory --name /opt/foo --mode 0755
  os.directory --name /opt/a/b/c --parent true --mode 0755
}

update() {
  os.directory --name /opt/foo --mode 0750
}

delete() {
  os.directory --name /opt/foo --state absent
  os.directory --name /opt/a/b/c --parent true --state absent
}

teardown() {
  return
}
