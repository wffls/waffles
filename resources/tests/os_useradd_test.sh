os.useradd.test.setup() {
  os.groupadd --group jdoe --gid 999
}

os.useradd.test.create() {
  os.useradd --user jdoe --gid 999 --uid 999 --homedir /home/jdoe
}

os.useradd.test.update() {
  os.useradd --user jdoe --gid 999 --uid 999 --homedir /home/jdoe --groups sudo
}

os.useradd.test.delete() {
  os.useradd --state absent --user jdoe
}

os.useradd.test.teardown() {
  os.groupadd --state absent --group jdoe
}
