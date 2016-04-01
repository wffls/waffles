# System Variables

`lib/system.sh` contains variables that can be used throughout your scripts.

## profile_files

Returns the path to the profile files directory.

```shell
echo $profile_files
/etc/waffles/site/profiles/memcached/files

os.file --name /tmp/foo.txt --source "$profile_files/foo.txt"
```

## profile_name

Returns the name of the profile currently being run.

```shell
echo $profile_name
memcached
```

## profile_path

Returns the path of the profle currently being run.

```shell
echo $profile_path
/etc/waffles/site/profiles/memcached
```

## role

Returns the role currently being run.

```shell
echo $role
memcached_server
```
