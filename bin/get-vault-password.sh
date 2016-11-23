#!/bin/bash -eu
#
help(){
cat<<\TIP

 if the file specified by "vault_password_file = <file>" in ansible.cfg or
   `ansible-playbook --vault-password-file=<file>` is executable then Ansible
   will run instead of read

 you could use this feature to fetch a credential from AWS's DynamoDB with
   fields encrypted by KMS so you don't have to type the vault password, or
 $ credstash get root@oob001.example.com

 call gpg to print the plaintext of a secret
 $ gpg -d ~/etc/root-oob001.gpg

TIP
}
help
