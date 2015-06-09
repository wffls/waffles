# stdlib_global_catalog holds entries for all resources declared.
# it's used to enforce only a single resource has been declared.
declare -Ag stdlib_global_catalog

function stdlib.catalog.add {
  if [[ -n $1 ]]; then
    if [[ ${stdlib_global_catalog[$1]+exists} ]]; then
      if [[ $WAFFLES_EXIT_ON_DUPLICATE_RESOURCE == true ]]; then
        stdlib.error "Duplicate resource detected: $1"
        exit 1
      else
        stdlib.warn "Duplicate resource detected: $1"
      fi
    else
      stdlib_global_catalog["$1"]=1
    fi
  fi
}

function stdlib.catalog.exists? {
  [ ${stdlib_global_catalog[$1]+exists} ]
}
