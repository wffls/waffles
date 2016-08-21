_apt_pkg_name="${apt_pkg_name:-openssl}"
_apt_pkg_install_version="${apt_pkg_install_version:-1.0.1f-1ubuntu2}"
_apt_pkg_update_version="${apt_pkg_update_version:-latest}"

apt.pkg.test.setup() {
  return
}

apt.pkg.test.create() {
  apt.pkg --name $_apt_pkg_name --version $_apt_pkg_install_version
}

apt.pkg.test.update() {
  apt.pkg --name $_apt_pkg_name --version $_apt_pkg_update_version
}

apt.pkg.test.delete() {
  apt.pkg --state absent --name $_apt_pkg_name
}

apt.pkg.test.teardown() {
  return
}
