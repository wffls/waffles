setup() {
  return
}

create() {
  os.file --name /root/role.txt --mode 0644 --content "role=memcache"
}

update() {
  os.file --name /root/role.txt --mode 0640 --content "role=memcached"
}

delete() {
  os.file --name /root/role.txt --state absent
}

teardown() {
  return
}
