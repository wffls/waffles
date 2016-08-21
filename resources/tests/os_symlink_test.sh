os.symlink.test.setup() {
  os.file --name /usr/local/bin/foo1
  os.file --name /usr/local/bin/foo2
  os.file --name /usr/local/bin/foo3
}

os.symlink.test.create() {
  os.symlink --name /usr/bin/foo1 --target /usr/local/bin/foo1
  os.symlink --name /usr/bin/foo2 --target /usr/local/bin/foo2
  os.symlink --name /usr/bin/foo3 --target /usr/local/bin/foo3
}

os.symlink.test.update() {
  os.symlink --name /usr/bin/foo2 --target /usr/local/bin/foo3 --overwrite true
}

os.symlink.test.delete() {
  os.symlink --name /usr/bin/foo1 --state absent
  os.symlink --name /usr/bin/foo2 --state absent
  os.symlink --name /usr/bin/foo3 --state absent
}

os.symlink.test.teardown() {
  os.file --name /usr/local/bin/foo1 --state absent
  os.file --name /usr/local/bin/foo2 --state absent
  os.file --name /usr/local/bin/foo3 --state absent
}
