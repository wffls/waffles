file.line.test.setup() {
  apt.pkg --name memcached
}

file.line.test.create() {
  file.line --file /root/file.txt --line foobar
  file.line --file /etc/memcached.conf --line "-m 128" --match "^-m"
}

file.line.test.update() {
  file.line --file /root/file.txt --line foobar
  file.line --file /etc/memcached.conf --line "-m 256" --match "^-m"
}

file.line.test.delete() {
  file.line --file /root/file.txt --line foobar --state absent
  file.line --file /etc/memcached.conf --line "-m 256" --match "^-m" --state absent
}

file.line.test.teardown() {
  apt.pkg --name memcached --state absent
}
