# augeas.json_array

## Description

Manages a dictionary entry in a JSON file

## Parameters

* state: The state of the resource. Required. Default: present.
* path: The path to the setting in the json tree for non-k/v settings.
* key: The key of the dictionary that will hold the array.
* value: The value of the array. Multi-var.
* file: The file to add the variable to. Required.

## Example

```shell
augeas.json_array --file /root/web.json --path / --key foo --value 1 --value 2 --value 3

{"foo":[1,2,3]}
```

