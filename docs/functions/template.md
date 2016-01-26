# Template Functions

[TOC]

`lib/stdlib/template.sh` contains functions related to templating.

## stdlib.render_template

`stdlib.render_template` requires the following two options:

* `--template`: The path to the template file.
* `--variables`: The name of a Bash associative array / hash that contains the variables to interpolate.

`stdlib.render_template` will then echo the rendered template.

### Example ###

```shell
$ cat profiles/test/files/test.tpl

Hello, {{ name }}!
Foo: {{ foo }}
Bar: {{ bar }}

$ cat profiles/test/data.sh

declare -Ag data_template_vars=()
data_template_vars[name]="Joe"
data_template_vars[foo]="foobar"
data_template_vars[bar]="barfoo"

$ cat profiles/test/scripts/template_test.sh

output=$(stdlib.render_template --template "$profile_files/test.tpl" --variables data_template_vars)
stdlib.file --name /tmp/rendered.txt --contents "$output"
```
