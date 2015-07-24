#!/bin/bash

function gendoc {
  _line_count=0
  _name=$1
  _file=$2

  while read -r line; do
    let "_line_count++"
    if [[ $line =~ ^function ]]; then
      break
    fi

    if [[ $line =~ ^# ]]; then
      _line=$(echo "$line" | sed -e 's/#//g' -e 's/^ //g' -e 's/^=//' -e 's/==/##/g')
      if [[ $_line_count -eq 3 ]]; then
        echo "# $_name" > "../resources/$_name.md"
      fi

      if [[ $_line_count -gt 3 ]]; then
        echo "$_line" >> "../resources/$_name.md"
      fi
    fi
  done < $_file
  echo "    - ${_name}: 'resources/${_name}.md'" >> ../../mkdocs.yml
}

cp mkdocs.yml.base ../../mkdocs.yml

for file in $(find ../../lib/resources -name \*.sh | sort); do
  _name="stdlib.$(basename $file | sed -e 's/\.sh//g')"
  gendoc "$_name" "$file"
done

for category in apache augeas consul keepalived mysql nginx rabbitmq; do
  for file in $(find ../../lib/$category/resources -name \*.sh | sort); do
    _name="$(basename $file | sed -e 's/\.sh//g' -e "s/${category}_/${category}./")"
    gendoc "$_name" "$file"
  done
done
