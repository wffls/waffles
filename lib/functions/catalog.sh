# waffles_catalog_changes keeps track of how many changes were made throughout the
# entire run of Waffles
declare -g waffles_catalog_changes=0

# waffles_catalog holds entries for all resources declared.
# it's used to enforce only a single resource has been declared.
declare -Ag waffles_catalog

function waffles.catalog.add {
  if [[ -n $1 ]]; then
    if [[ ${waffles_catalog[$1]+exists} ]]; then
      if [[ -n $WAFFLES_EXIT_ON_DUPLICATE_RESOURCE ]]; then
        log.error "Duplicate resource detected: $1"
        exit 1
      else
        log.warn "Duplicate resource detected: $1"
      fi
    else
      waffles_catalog[$1]=1
    fi
  fi
}

function waffles.catalog.exists {
  [ ${waffles_catalog[$1]+exists} ]
}
