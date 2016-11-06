setup() {
  os.file --name /usr/local/bin/foo1
  os.file --name /usr/local/bin/foo2
  os.file --name /usr/local/bin/foo3
}

create() {
  os.symlink --name /usr/bin/foo1 --target /usr/local/bin/foo1
  os.symlink --name /usr/bin/foo2 --target /usr/local/bin/foo2
  os.symlink --name /usr/bin/foo3 --target /usr/local/bin/foo3
}

update() {
  os.symlink --name /usr/bin/foo2 --target /usr/local/bin/foo3 --overwrite true
}

delete() {
  os.symlink --name /usr/bin/foo1 --state absent
  os.symlink --name /usr/bin/foo2 --state absent
  os.symlink --name /usr/bin/foo3 --state absent
}

teardown() {
  os.file --name /usr/local/bin/foo1 --state absent
  os.file --name /usr/local/bin/foo2 --state absent
  os.file --name /usr/local/bin/foo3 --state absent
}
