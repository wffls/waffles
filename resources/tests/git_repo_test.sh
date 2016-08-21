git.repo.test.setup() {
  apt.pkg --name git
}

git.repo.test.create() {
  git.repo --name /opt/waffles --source https://github.com/wffls/waffles
}

git.repo.test.update() {
  git.repo --name /opt/waffles --source https://github.com/wffls/waffles --commit 5c03d70730acbc588e
}

git.repo.test.delete() {
  git.repo --name /opt/waffles --source https://github.com/wffls/waffles --state absent
}

git.repo.test.teardown() {
  apt.pkg --name git --state absent
}
