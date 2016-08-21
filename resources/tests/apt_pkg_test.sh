_apt_pkg_name="${apt_pkg_name:-openssl}"
_apt_pkg_install_version="${apt_pkg_install_version:-1.0.1f-1ubuntu2}"
_apt_pkg_update_version="${apt_pkg_update_version:-latest}"

create() {
  apt.pkg --name $_apt_pkg_name --version $_apt_pkg_install_version
}

update() {
  apt.pkg --name $_apt_pkg_name --version $_apt_pkg_update_version
}

delete() {
  apt.pkg --state absent --name $_apt_pkg_name
}
