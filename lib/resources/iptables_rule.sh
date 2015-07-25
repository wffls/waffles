# == Name
#
# stdlib.iptables_rule
#
# === Description
#
# Manages iptables rules
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: An arbitrary name for the rule. Required. namevar.
# * priority: An arbitrary number to give the rule priority. Required. Default 100.
# * table: The table to add the rule to.. Required. Default: filter.
# * chain: The chain to add the rule to. Required. Default: INPUT.
# * rule: The rule. Required.
# * action: The action to take on the rule. Required. Default: ACCEPT.
#
# === Example
#
# ```shell
# stdlib.iptables_rule --priority 100 --name "allow all from 192.168.1.0/24" --rule "-m tcp -s 192.168.1.0/24" --action ACCEPT
# ```
#
function stdlib.iptables_rule {
  stdlib.subtitle "stdlib.iptables_rule"

  # Resource Options
  local -A options
  stdlib.options.create_option state    "present"
  stdlib.options.create_option name     "__required__"
  stdlib.options.create_option priority "100"
  stdlib.options.create_option table    "filter"
  stdlib.options.create_option chain    "INPUT"
  stdlib.options.create_option rule     "__required__"
  stdlib.options.create_option action   "ACCEPT"
  stdlib.options.parse_options "$@"

  # Local Variables
  local rule="${options[chain]} ${options[rule]} -m comment --comment \"${options[priority]} ${options[name]}\" -j ${options[action]}"

  # Process the resource
  stdlib.resource.process "stdlib.iptables_rule" "$rule"
}

function stdlib.iptables_rule.read {
  iptables -t "${options[table]}" -S "${options[chain]}" | grep -q "comment \"${options[priority]} ${options[name]}\""
  if [[ $? != 0 ]]; then
    stdlib_current_state="absent"
    return
  fi

  iptables -t "${options[table]}" -C "${options[chain]}" $rule 2>/dev/null
  if [[ $? == 1 ]]; then
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function stdlib.iptables_rule.create {
  local rulenum=0
  local added="false"

  local -a oldrules
  mapfile -t oldrules < <(iptables -t ${options[table]} -S "${options[chain]}" | grep -v ^-P)
  if [[ ${#oldrules[@]} == 0 ]]; then
    stdlib.capture_error "iptables -t ${options[table]} -I $rule"
    added="true"
  else
    for oldrule in "${oldrules[@]}"; do
      rulenum=$((rulenum+1))
      local oldcomment=$(echo $oldrule | sed -e 's/.*--comment "\(.*\)".*/\1/')
      if [[ ! $oldcomment =~ ^- ]]; then
        local priority=$(echo $oldcomment | cut -d' ' -f1)
        if [[ $priority > ${options[priority]} ]]; then
          stdlib.capture_error "iptables -t ${options[table]} -I $rulenum $oldrule"
          added="true"
          break
        fi
      fi
    done
  fi

  if [[ $added == "false" ]]; then
    stdlib.capture_error "iptables -t ${options[table]} -A $rule"
  fi
}

function stdlib.iptables_rule.update {
  local _rule=$(iptables -S -t ${options[table]} "${options[chain]}" | grep "comment \"${options[priority]} ${options[name]}\"" | sed -e 's/^-A/-D/')
  stdlib.capture_error "iptables -t ${options[table]} $_rule"
  stdlib.capture_error "iptables -t ${options[table]} $rule"
}

function stdlib.iptables_rule.delete {
  local _rule=$(iptables -S -t ${options[table]} "${options[chain]}" | grep "comment \"${options[priority]} ${options[name]}\"" | sed -e 's/^-A/-D/')
  stdlib.capture_error "iptables -t ${options[table]} $_rule"
}
