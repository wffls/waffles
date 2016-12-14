setup() {
  apt.pkg --name memcached
}

create() {
  file.line --file /root/file.txt --line foobar
  file.line --file /etc/memcached.conf --line "-m 128" --match "^-m"
}

update() {
  file.line --file /root/file.txt --line foobar
  file.line --file /etc/memcached.conf --line "-m 256" --match "^-m"
}

delete() {
  file.line --file /root/file.txt --line foobar --state absent
  file.line --file /etc/memcached.conf --line "-m 256" --match "^-m" --state absent
}

teardown() {
  apt.pkg --name memcached --state absent
}
