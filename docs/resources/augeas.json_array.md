# augeas.json_array

## Description

Manages a dictionary entry in a JSON file

## Parameters

* state: The state of the resource. Required. Default: present.
* path: The path to the setting in the json tree for non-k/v settings.
* key: The key of the dictionary that will hold the array.
* value: The array. Will be eval'd as a bash array.
* file: The file to add the variable to. Required.

## Example

```shell
augeas.json_array --file /root/web.json --path / --key foo --value "1 2 3 4"

{"foo":[1,2,3]}
```

