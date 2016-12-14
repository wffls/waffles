setup() {
  apt.pkg --name git
}

create() {
  git.repo --name /opt/waffles --source https://github.com/wffls/waffles
}

update() {
  git.repo --name /opt/waffles --source https://github.com/wffls/waffles --commit 5c03d70730acbc588e
}

delete() {
  git.repo --name /opt/waffles --source https://github.com/wffls/waffles --state absent
}

teardown() {
  apt.pkg --name git --state absent
}
