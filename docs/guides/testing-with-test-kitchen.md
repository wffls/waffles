# Testing With Test Kitchen

## Description

This guide will show how to set up Test Kitchen so you can run various acceptance and integration tests on Waffles.

## Steps

1. Provision a virtual machine that will be used for Test Kitchen.

2. Run the following commands:

```shell
apt-get update
apt-get install -y ruby
wget -qO- https://get.docker.com/
gem install test-kitchen
gem install kitchen-docker
gem install busser-bash
gem install busser-bats
gem install busser-serverspec
kitchen init --driver=kitchen-docker
```

3. Download Waffles to `/root/.waffles`.

4. The `/root/.waffles/kitchen` directory contains everything you need to get started with testing. Review `/root/.waffles/kitchen/.kitchen.yml` and make any necessary changes.

5. Type the following command to run all tests:

```shell
cd /root/.waffles/kitchen
kitchen test
```

## Comments

For information on how to use Test Kitchen, see the [Test Kitchen](http://kitchen.ci) home page.
