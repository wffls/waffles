setup() {
  os.file --name /root/test.ini
}

create() {
  file.ini --file /root/test.ini --section __none__ --option global --value setting
  file.ini --file /root/test.ini --section foobar --option foo --value bar
  file.ini --file /root/test.ini --section foobar --option baz --value __none__
}

update() {
  file.ini --file /root/test.ini --section __none__ --option global --value setting2
  file.ini --file /root/test.ini --section foobar --option foo --value bar
  file.ini --file /root/test.ini --section foobar --option baz --value __none__
}

delete() {
  file.ini --file /root/test.ini --section __none__ --option global --value setting2 --state absent
  file.ini --file /root/test.ini --section foobar --option foo --value bar2 --state absent
  file.ini --file /root/test.ini --section foobar --option baz --value __none__2 --state absent
}

teardown() {
  os.file --name /root/test.ini --state absent
}
