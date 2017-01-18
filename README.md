stacki-frontend
=========

Ansible tooling for [Stacki](http://www.stacki.com/), a dandy little kickstart configurator and bootstrapping appliance for CentOS

Requirements
------------

- netsheet: a .csv file describing the subnets on which the frontend is homed
  and on which the backend targets will be provisioned or permanently homed or
  both
- storagesheet: a .csv file describing the storage layout for the current batch
  of backend targets
- kicksheet: a .csv file describing the backend targets that should be
  bootstrapped via Kickstart (if you happen to be building on Dell metal you can
  use the included kickdrac.sh script to compose this file)
- unkicksheet: a .csv file of previously-kicked backend targets that should be
  removed from the frontend's host inventory so they are not re-installed
- set root's password shadow/hash in
  files/export/stack/carts/root/nodes/cart-root-backend.xml


Role Variables
--------------

- stacki_appliance: this must be "backend" for now. I ran into some errors when
  I tried to maintain multiple appliance names with discrete storage layouts. It
  would be nice to add that in the future, though.
- massdevice: the short name of the block device where the storage layout should
  be applied (e.g. "sda", "vdb")


Example Playbook
----------------

from stacki-frontend.yml
````yaml
---

# This is YAML and indentation is meaningful, but not strict. For example, you
# could indent two or four spaces (but not tabs) to start a list so long as you
# are consistent for that logical layer of the data structure.

- hosts:
  # use 'all' here if you're also giving a comma-separated list of domain
  # names as an argument to `ansible-playbook --inventory` or wish to target all
  # hosts in the inventory file
 #- all
  # otherwise, give the name of a host group in the inventory file
  - pxe-bld403
  roles:
  # you could comment the role below to verify dependencies with the ping task
 #- stacki-frontend
  tasks:
  - ping:
  vars:
  # this is always "backend" for now because there were errors when trying to
  # maintain multiple appliances; it seems easier to just declare a new
  # configuration for the default appliance for each build cycle
    stacki_appliance: backend
  # the device name that will populate the storage.csv file
    massdevice: sda # M820
    #massdevice: vda # oVirt guest

...
````


Incantation
----------------


**ssh as root with a password and execute on the host groups named in the stacki-frontend.yml playbook file**
````shell
ANSIBLE_CONFIG=ansible.cfg ansible-playbook \
  --inventory hosts-stacki-frontend.txt \
  --user root --ask-pass \
  stacki-frontend.yml
````

**ssh as root without a password (because another auth method is enabled) and execute on the comma-separated list (note the trailing comma) any tasks or roles specified in the stacki-frontend.yml playbook file**
````shell
ANSIBLE_CONFIG=ansible.cfg ansible-playbook \
  --inventory 'pxe001.bld403.vdc1.example.com,' \
  --user root \
  stacki-frontend.yml
````

License
-------

BSD

Author Information
------------------

[Kenneth Bingham](http://w.qrk.us) <w@qrk.us> (2016)


