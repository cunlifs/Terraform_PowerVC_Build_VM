################################################################
# Module to deploy via IBM PowerVC
# Author: Stu Cunliffe
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# Copyright IBM Corp. 2017.
#
################################################################

provider "openstack" {
    user_name   = var.openstack_user_name
    password    = var.openstack_password
    tenant_name = var.openstack_new_project_name
    domain_name = var.openstack_domain_name
    auth_url    = var.openstack_auth_url
    insecure    = true
}

resource "random_id" "rand" {
    byte_length = 2
}

resource "openstack_compute_keypair_v2" "vm-key-pair" {
    name       = "terraform-vm-key-pair-${random_id.rand.hex}"
    public_key = file("${var.openstack_ssh_key_file}.pub")
}

resource "openstack_compute_instance_v2" "sc-app-vm" {
    count     = 2
    name      = format("sc-app-aix-vm-${random_id.rand.hex}-%02d", count.index+1)
    image_id  = var.openstack_image_id_AIX7_2
    flavor_id = var.openstack_flavor_id_node_small
    key_pair  = openstack_compute_keypair_v2.vm-key-pair.name

    network {
        uuid = var.openstack_network_id
        name = var.openstack_network_name
    }

#    user_data = file("bootstrap_icp_worker.sh")
}

resource "openstack_compute_instance_v2" "sc-db-vm" {
    count     = 1
    name      = format("sc-db-aix-vm-${random_id.rand.hex}-%02d", count.index+1)
    image_id  = var.openstack_image_id_AIX7_2
    flavor_id = var.openstack_flavor_id_node_medium
    key_pair  = openstack_compute_keypair_v2.vm-key-pair.name

    network {
        uuid = var.openstack_network_id
        name = var.openstack_network_name
    }
}

resource "openstack_blockstorage_volume_v3" "volume" {
  count       = 1
  name        = format("volume-${random_id.rand.hex}-%02d", count.index+1)
  description = "Volume created by terraform"
  size        = 3
}

resource "openstack_compute_volume_attach_v2" "va_1" {
  volume_id  = openstack_blockstorage_volume_v3.volume[0].id
  instance_id  = openstack_compute_instance_v2.sc-app-vm[0].id
}

resource "openstack_images_image_v2" "RedHatCoreOS_Image" {
  name             = "RedHat_Core_OS"
  image_source_url = "https://mirror.openshift.com/pub/openshift-v4/ppc64le/dependencies/rhcos/latest/4.6.1/rhcos-live-rootfs.ppc64le.img"
  container_format = "bare"
  disk_format      = "qcow2"
}
