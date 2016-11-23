# stacki-frontend
Ansible tooling for [Stacki](http://www.stacki.com/), a dandy little kickstart configurator and bootstrapping appliance for CentOS

### examples for *nix shell

###### ssh as root with a password and execute on the host groups named in the stacki-frontend.yml playbook file
````
ANSIBLE_CONFIG=ansible.cfg ansible-playbook \
  --inventory hosts-stacki-frontend.txt \
  --user root --ask-pass \
  stacki-frontend.yml
````

###### ssh as root without a password (because another auth method is enabled) and execute on the comma-separated list (note the trailing comma) any tasks or roles specified in the stacki-frontend.yml playbook file
````
ANSIBLE_CONFIG=ansible.cfg ansible-playbook \
  --inventory 'pxe001.bld403.example.com,' \
  --user root \
  stacki-frontend.yml
````
