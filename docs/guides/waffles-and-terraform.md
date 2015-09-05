# Using Waffles with Terraform

[TOC]

## Description

This guide will show how to use Waffles with [Terraform](http://terraform.io). The Terraform OpenStack provider will be used, but these concepts should be applicable to any provider.

## Steps

### Installing Terraform

First, set up and install Terraform. Instructions can be found on Terraform's [homepage](http://terraform.io).

### Creating a Terraform Configuration

The following Terraform Configuration is all that is required to use Waffles with Terraform:

```ruby
resource "openstack_compute_keypair_v2" "waffles" {
  name = "waffles"
  public_key = "${file("/root/.ssh/id_rsa.pub")}"
}

resource "openstack_compute_instance_v2" "waffles" {
  name = "waffles"
  image_name = "Ubuntu 14.04"
  flavor_name = "m1.tiny"

  key_pair = "${openstack_compute_keypair_v2.waffles.name}"
  security_groups = ["default"]

  connection {
    user = "ubuntu"
    key_file = "/root/.ssh/id_rsa"
    host = "${openstack_compute_instance_v2.waffles.access_ip_v6}"
  }

  provisioner "local-exec" {
    command = "sleep 10 && cd /root/.waffles && bash waffles.sh -r memcached -s ${openstack_compute_instance_v2.waffles.access_ip_v6} -u ubuntu -y"
  }

}
```

Save the above as something like `~/waffles-tform/main.tf`

### Apply the Terraform Configuration

Now just apply the configuration with:

```shell
$ cd waffles-tform
$ terraform apply
```

## Comments

The above configuration makes a few assumptions:

* `rsync` is already installed on the image you'll be using. If yours doesn't, use `cloud-init` or a similar system to pre-install it.
* The virtual machine that Terraform creates is accessible via IPv6. If yours isn't, either attach a Floating or Elastic IP or use the fixed IP somehow.
* The SSH key being used is `/root/.ssh/id_rsa`. This is because Waffles does not support non-default SSH keys yet.
* SSH access is allowed through the security group.


## Conclusion

This guide showed one way of using Waffles with Terraform. Both systems are extremely flexible and complement each other well, so there may be other ways of achieving the same result.

For example, you could use Terraform's `file` provisioner to copy the entire `~/.waffles` directory to the remote virtual machine. The benefit of using Waffles's built-in push is that only the files which the role requires are copied over.
