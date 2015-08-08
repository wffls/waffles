# augeas.generic

## Description

Change a file using Augeas

## Parameters

* state: The state of the resource. Required. Default: present.
* name: An arbitrary name for the resource. Required. namevar.
* lens: The Augeas lens to use without the .lns extension. Required.
* lens_path: A custom directory that contain lenses. Optional. Multi-var.
* command: A single Augeas command to run. Optional. Multi-var.
* onlyif: A match conditional to check prior to running commands. If `true`, the command(s) are run. Optional.
* file: The file to modify. Required. namevar.

## onlyif Conditional Tests

`onlyif` tests have the following format:

```shell
--onlyif "<path> <function> <operator> <comparison>"
```

### Size

Size compares the amount of matches.

* `size -lt 1`
* `size -gt 1`
* Any numerical comparisons

### Path

* Will compare the returned path(s) with a string:

* `path not_include <string>`
* `path include <string>`

### Result

Result will compare the returned result(s) with a string:

* `result not_include <string>`
* `result include <string>`

### Conditional Test Examples

Assume `/files/etc/hosts`:

* `*/ipaddr[. =~ regexp("127.*")]`
* `*/ipaddr[. =~ regexp("127.*")] size -lt 1`
* `*/ipaddr[. =~ regexp("127.*")] size -gt 1`
* `*/ipaddr[. =~ regexp("127.*")] path not_include 127.0.0.1`
* `*/ipaddr[. = "127.0.0.1"]/../canonical result include localhost`

## Example

```shell
augeas.generic --name test --lens Hosts --file /root/hosts \
  --command "set *[canonical = 'localhost'][1]/ipaddr '10.3.3.27'" \
  --onlyif "*/ipaddr[. = '127.0.0.1']/../canonical result include 'localhost'"

augeas.generic --name test2 --lens Hosts --file /root/hosts \
  --command "set 0/ipaddr '8.8.8.8'" \
  --command "set 0/canonical 'google.com'" \
  --onlyif "*/ipaddr[. = '8.8.8.8'] result not_include '8.8.8.8'"

augeas.generic --name test3 --lens Hosts --file /root/hosts \
  --command "set 0/ipaddr '1.1.1.1'" \
  --command "set 0/canonical 'foobar.com'" \
  --onlyif "*/ipaddr[. = '1.1.1.1'] path not_include 'ipaddr'"

augeas.generic --name test4 --lens Hosts --file /root/hosts \
  --command "set 0/ipaddr '2.2.2.2'" \
  --command "set 0/canonical 'barfoo.com'" \
  --onlyif "*/ipaddr[. = '2.2.2.2'] size ## 0"

augeas.generic --name test5 --lens Hosts --file /root/hosts \
  --command "set 0/ipaddr '3.3.3.3'" \
  --command "set 0/canonical 'bazbar.com'" \
  --onlyif "*/ipaddr[. = '3.3.3.3'] size -lt 1"
```

