file.ini.test.setup() {
  os.file --name /root/test.ini
}

file.ini.test.create() {
  file.ini --file /root/test.ini --section __none__ --option global --value setting
  file.ini --file /root/test.ini --section foobar --option foo --value bar
  file.ini --file /root/test.ini --section foobar --option baz --value __none__
}

file.ini.test.update() {
  file.ini --file /root/test.ini --section __none__ --option global --value setting2
  file.ini --file /root/test.ini --section foobar --option foo --value bar
  file.ini --file /root/test.ini --section foobar --option baz --value __none__
}

file.ini.test.delete() {
  file.ini --file /root/test.ini --section __none__ --option global --value setting2 --state absent
  file.ini --file /root/test.ini --section foobar --option foo --value bar2 --state absent
  file.ini --file /root/test.ini --section foobar --option baz --value __none__2 --state absent
}

file.ini.test.teardown() {
  os.file --name /root/test.ini --state absent
}
