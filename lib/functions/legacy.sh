function stdlib.apt_key {
  log.warn "Calling deprecated stdlib.apt_key"
  apt.key "$@"
}
function stdlib.apt_key.read {
  apt.key.read "$@"
}
function stdlib.apt_key.create {
  apt.key.create "$@"
}
function stdlib.apt_key.update {
  apt.key.update "$@"
}
function stdlib.apt_key.delete {
  apt.key.delete "$@"
}

function stdlib.apt_ppa {
  log.warn "Calling deprecated stdlib.apt_ppa"
  apt.ppa "$@"
}
function stdlib.apt_ppa.read {
  apt.ppa.read "$@"
}
function stdlib.apt_ppa.create {
  apt.ppa.create "$@"
}
function stdlib.apt_ppa.update {
  apt.ppa.update "$@"
}
function stdlib.apt_ppa.delete {
  apt.ppa.delete "$@"
}

function stdlib.apt {
  log.warn "Calling deprecated stdlib.apt"
  apt.pkg "$@"
}
function stdlib.apt.read {
  apt.pkg.read "$@"
}
function stdlib.apt.create {
  apt.pkg.create "$@"
}
function stdlib.apt.update {
  apt.pkg.update "$@"
}
function stdlib.apt.delete {
  apt.pkg.delete "$@"
}

function stdlib.apt_source {
  log.warn "Calling deprecated stdlib.apt_source"
  apt.source "$@"
}
function stdlib.apt_source.read {
  apt.source.read "$@"
}
function stdlib.apt_source.create {
  apt.source.create "$@"
}
function stdlib.apt_source.update {
  apt.source.update "$@"
}
function stdlib.apt_source.delete {
  apt.source.delete "$@"
}

function stdlib.cron {
  log.warn "Calling deprecated stdlib.cron"
  cron.entry "$@"
}
function stdlib.cron.read {
  cron.entry.read "$@"
}
function stdlib.cron.create {
  cron.entry.create "$@"
}
function stdlib.cron.update {
  cron.entry.update "$@"
}
function stdlib.cron.delete {
  cron.entry.delete "$@"
}

function stdlib.debconf {
  log.warn "Calling deprecated stdlib.debconf"
  dpkg.debconf "$@"
}
function stdlib.debconf.read {
  dpkg.debconf.read "$@"
}
function stdlib.debconf.create {
  dpkg.debconf.create "$@"
}
function stdlib.debconf.update {
  dpkg.debconf.update "$@"
}
function stdlib.debconf.delete {
  dpkg.debconf.delete "$@"
}

function stdlib.directory {
  log.warn "Calling deprecated stdlib.directory"
  os.directory "$@"
}
function stdlib.directory.read {
  os.directory.read "$@"
}
function stdlib.directory.create {
  os.directory.create "$@"
}
function stdlib.directory.update {
  os.directory.update "$@"
}
function stdlib.directory.delete {
  os.directory.delete "$@"
}

function stdlib.file_line {
  log.warn "Calling deprecated stdlib.file_line"
  file.line "$@"
}
function stdlib.file_line.read {
  file.line.read "$@"
}
function stdlib.file_line.create {
  file.line.create "$@"
}
function stdlib.file_line.update {
  file.line.update "$@"
}
function stdlib.file_line.delete {
  file.line.delete "$@"
}

function stdlib.file {
  log.warn "Calling deprecated stdlib.file"
  os.file "$@"
}
function stdlib.file.read {
  os.file.read "$@"
}
function stdlib.file.create {
  os.file.create "$@"
}
function stdlib.file.update {
  os.file.update "$@"
}
function stdlib.file.delete {
  os.file.delete "$@"
}

function stdlib.git {
  log.warn "Calling deprecated stdlib.git"
  git.repo "$@"
}
function stdlib.git.read {
  git.repo.read "$@"
}
function stdlib.git.create {
  git.repo.create "$@"
}
function stdlib.git.update {
  git.repo.update "$@"
}
function stdlib.git.delete {
  git.repo.delete "$@"
}

function stdlib.groupadd {
  log.warn "Calling deprecated stdlib.groupadd"
  os.groupadd "$@"
}
function stdlib.groupadd.read {
  os.groupadd.read "$@"
}
function stdlib.groupadd.create {
  os.groupadd.create "$@"
}
function stdlib.groupadd.update {
  os.groupadd.update "$@"
}
function stdlib.groupadd.delete {
  os.groupadd.delete "$@"
}

function stdlib.ini {
  log.warn "Calling deprecated stdlib.ini"
  file.ini "$@"
}
function stdlib.ini.read {
  file.ini.read "$@"
}
function stdlib.ini.create {
  file.ini.create "$@"
}
function stdlib.ini.update {
  file.ini.update "$@"
}
function stdlib.ini.delete {
  file.ini.delete "$@"
}

function stdlib.ip6tables_rule {
  log.warn "Calling deprecated stdlib.ip6tables_rule"
  ip6tables.rule "$@"
}
function stdlib.ip6tables_rule.read {
  ip6tables.rule.read "$@"
}
function stdlib.ip6tables_rule.create {
  ip6tables.rule.create "$@"
}
function stdlib.ip6tables_rule.update {
  ip6tables.rule.update "$@"
}
function stdlib.ip6tables_rule.delete {
  ip6tables.rule.delete "$@"
}

function stdlib.iptables_rule {
  log.warn "Calling deprecated stdlib.iptables_rule"
  iptables.rule "$@"
}
function stdlib.iptables_rule.read {
  iptables.rule.read "$@"
}
function stdlib.iptables_rule.create {
  iptables.rule.create "$@"
}
function stdlib.iptables_rule.update {
  iptables.rule.update "$@"
}
function stdlib.iptables_rule.delete {
  iptables.rule.delete "$@"
}

function stdlib.sudo_cmd {
  log.warn "Calling deprecated stdlib.sudo_cmd"
  sudo.cmd "$@"
}
function stdlib.sudo_cmd.read {
  sudo.cmd.read "$@"
}
function stdlib.sudo_cmd.create {
  sudo.cmd.create "$@"
}
function stdlib.sudo_cmd.update {
  sudo.cmd.update "$@"
}
function stdlib.sudo_cmd.delete {
  sudo.cmd.delete "$@"
}

function stdlib.symlink {
  log.warn "Calling deprecated stdlib.symlink"
  os.symlink "$@"
}
function stdlib.symlink.read {
  os.symlink.read "$@"
}
function stdlib.symlink.create {
  os.symlink.create "$@"
}
function stdlib.symlink.update {
  os.symlink.update "$@"
}
function stdlib.symlink.delete {
  os.symlink.delete "$@"
}

function stdlib.sysvinit {
  log.warn "Calling deprecated stdlib.sysvinit"
  service.sysv "$@"
}
function stdlib.sysvinit.read {
  service.sysv.read "$@"
}
function stdlib.sysvinit.create {
  service.sysv.create "$@"
}
function stdlib.sysvinit.update {
  service.sysv.update "$@"
}
function stdlib.sysvinit.delete {
  service.sysv.delete "$@"
}

function stdlib.upstart {
  log.warn "Calling deprecated stdlib.upstart"
  service.upstart "$@"
}
function stdlib.upstart.read {
  service.upstart.read "$@"
}
function stdlib.upstart.create {
  service.upstart.create "$@"
}
function stdlib.upstart.update {
  service.upstart.update "$@"
}
function stdlib.upstart.delete {
  service.upstart.delete "$@"
}

function stdlib.useradd {
  log.warn "Calling deprecated stdlib.useradd"
  os.useradd "$@"
}
function stdlib.useradd.read {
  os.useradd.read "$@"
}
function stdlib.useradd.create {
  os.useradd.create "$@"
}
function stdlib.useradd.update {
  os.useradd.update "$@"
}
function stdlib.useradd.delete {
  os.useradd.delete "$@"
}

function stdlib.color? {
  log.warn "Calling deprecated stdlib.color?"
  waffles.color "$@"
}

function stdlib.debug {
  log.warn "Calling deprecated stdlib.debug"
  log.debug "$@"
}

function stdlib.info {
  log.warn "Calling deprecated stdlib.info"
  log.info "$@"
}

function stdlib.warn {
  log.warn "Calling deprecated stdlib.warn"
  log.warn "$@"
}

function stdlib.error {
  log.warn "Calling deprecated stdlib.error"
  log.error "$@"
}

function stdlib.noop? {
  log.warn "Calling deprecated stdlib.noop?"
  waffles.noop "$@"
}

function stdlib.debug? {
  log.warn "Calling deprecated stdlib.debug?"
  waffles.debug "$@"
}

function stdlib.title {
  log.warn "Calling deprecated stdlib.title"
  waffles.title "$@"
}

function stdlib.subtitle {
  log.warn "Calling deprecated stdlib.subtitle"
  waffles.subtitle "$@"
}

function stdlib.mute {
  log.warn "Calling deprecated stdlib.mute"
  exec.mute "$@"
}

function stdlib.debug_mute {
  log.warn "Calling deprecated stdlib.debug_mute"
  exec.debug_mute "$@"
}

function stdlib.exec {
  log.warn "Calling deprecated stdlib.exec"
  exec.run "$@"
}

function stdlib.capture_error {
  log.warn "Calling deprecated stdlib.capture_error"
  exec.capture_error "$@"
}

function stdlib.dir {
  log.warn "Calling deprecated stdlib.dir"
  waffles.dir "$@"
}

function stdlib.include {
  log.warn "Calling deprecated stdlib.include"
  waffles.include "$@"
}

function stdlib.profile {
  log.warn "Calling deprecated stdlib.profile"
  waffles.profile "$@"
}

function stdlib.git_profile {
  log.warn "Calling deprecated stdlib.git_profile"
  git.profile "$@"
}

function stdlib.data {
  log.warn "Calling deprecated stdlib.data"
  waffles.data "$@"
}

function stdlib.command_exists {
  log.warn "Calling deprecated stdlib.command_exists"
  waffles.command_exists "$@"
}

function stdlib.sudo_exec {
  log.warn "Calling deprecated stdlib.sudo_exec"
  exec.sudo "$@"
}

function stdlib.split {
  log.warn "Calling deprecated stdlib.split"
  string.split "$@"
}

function stdlib.trim {
  log.warn "Calling deprecated stdlib.trim"
  string.trim "$@"
}

function stdlib.array_length {
  log.warn "Calling deprecated stdlib.array_length"
  array.length "$@"
}

function stdlib.array_push {
  log.warn "Calling deprecated stdlib.array_push"
  array.push "$@"
}

function stdlib.array_pop {
  log.warn "Calling deprecated stdlib.array_pop"
  array.pop "$@"
}

function stdlib.array_shift {
  log.warn "Calling deprecated stdlib.array_shift"
  array.shift "$@"
}

function stdlib.array_unshift {
  log.warn "Calling deprecated stdlib.array_unshift"
  array.unshift "$@"
}

function stdlib.array_join {
  log.warn "Calling deprecated stdlib.array_join"
  array.join "$@"
}

function stdlib.array_contains {
  log.warn "Calling deprecated stdlib.array_contains"
  array.contains "$@"
}

function stdlib.hash_keys {
  log.warn "Calling deprecated stdlib.hash_keys"
  hash.keys "$@"
}

function stdlib.build_ini_file {
  log.warn "Calling deprecated stdlib.build_ini_file"
  waffles.build_ini_file "$@"
}

function stdlib.enable_augeas {
  log.warn "stdlib.enable_augeas is no longer required."
}

function stdlib.enable_mysql {
  log.warn "stdlib.enable_mysql is no longer required."
}

function stdlib.enable_rabbitmq {
  log.warn "stdlib.enable_rabbitmq is no longer required."
}

function stdlib.enable_nginx {
  log.warn "stdlib.enable_nginx is no longer required."
}

function stdlib.enable_apache {
  log.warn "stdlib.enable_apache is no longer required."
}

function stdlib.enable_keepalived {
  log.warn "stdlib.enable_keepalived is no longer required."
}

function stdlib.enable_consul {
  log.warn "stdlib.enable_consul is no longer required."
}

function stdlib.enable_python {
  log.warn "stdlib.enable_python is no longer required."
}
