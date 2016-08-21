os.file.test.setup() {
  return
}

os.file.test.create() {
  os.file --name /root/role.txt --mode 0644 --content "role=memcache"
}

os.file.test.update() {
  os.file --name /root/role.txt --mode 0640 --content "role=memcached"
}

os.file.test.delete() {
  os.file --name /root/role.txt --state absent
}

os.file.test.teardown() {
  return
}
