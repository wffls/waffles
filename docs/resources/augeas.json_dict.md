# augeas.json_dict

## Description

Manages a dictionary entry in a JSON file

## Parameters

* state: The state of the resource. Required. Default: present.
* path: The path to the setting in the json tree for non-k/v settings.
* key: The key portion of the dictionary.
* value: The value portion of the dictionary.
* file: The file to add the variable to. Required.

## Example

```shell
augeas.json_dict --file /root/web.json --path / --key "foo" --value _dict
augeas.json_dict --file /root/web.json --path / --key "foo" --value _array
augeas.json_dict --file /root/web.json --path / --key "foo" --value "bar"
```

