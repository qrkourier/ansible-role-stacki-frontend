#!/bin/bash -eu
#
# improvements welcome:
#   https://github.com/qrkourier/stacki-frontend
#

doracadm(){
# this function runs a remote command on an iDRAC
# and accepts two params:
# 1 = the racadm subcommand, args, and options enclosed in quotes
# 2 = the iDRAC FQDN
echo "doing \"$1\" on $2"
sshpass -e \
  ssh -o StrictHostKeyChecking=no root@$2 racadm "$1"
}

getethernet(){
# this function returns the Ethernet address of the first integrated NIC for
# a given host and accepts one param:
# $1 = the iDRAC FQDN
doracadm "getsysinfo -s" $1|egrep "NIC.Integrated.1-1-1.*Ethernet"|egrep -o '([A-F0-9]{2}[:-]?){6}'|tr '-' ':'
}

kicklan(){
# this function prints the CSV line for a kicksheet for a particular host and
# accepts one param:
# $1 = the host's FQDN (not the iDRAC FQDN)
#printf '%s,%s,,backend,0,0,%s,%s,%s,%s,,,%s\n' \ # removing the vlan
printf '%s,%s,,backend,0,0,%s,%s,%s,%s,,,\n' \
  "${1%.${DSTLAN[0]}.*}" \
  "${1/.${DSTLAN[0]}.*/-${KICKLAN[0]}}" \
  "$(dig +short ${1/.${DSTLAN[0]}./.$KICKLAN.})" \
  "$(getethernet ${1/.${DSTLAN[0]}./.$MGTLAN.})" \
  "${KICKLAN[1]}" \
  "${KICKLAN[0]}" #\
  #"${KICKLAN[0]: -3:3}"
}

dstlan(){
# this function prints the CSV line for a kicksheet for a particular host and
# accepts one param:
# $1 = the host's FQDN (not the iDRAC FQDN)
printf '%s,%s,True,,,,%s,,%s,%s,,,%s\n' \
  "${1%.${DSTLAN[0]}.*}" \
  "${1/.${DSTLAN[0]}.*/-${DSTLAN[0]}}" \
  "$(dig +short $1)" \
  "${DSTLAN[1]}" \
  "${DSTLAN[0]}" \
  "${DSTLAN[0]: -3:3}"
}

kicksheet() {
# print the kicksheet
printf 'NAME,INTERFACE HOSTNAME,DEFAULT,APPLIANCE,RACK,RANK,IP,MAC,INTERFACE,NETWORK,CHANNEL,OPTIONS,VLAN\n'
for RNAME in ${NAMERANGE[*]};do
  HOSTFQDN=$RNAME.$DSTLAN.$SITE.${DOMAIN%.}
  kicklan $HOSTFQDN
  dstlan $HOSTFQDN
done
[[ $FLAGS =~ f ]] || \
  read -sp "If kicksheet deployed and switch configured for PXE then press ENTER to begin reboot sequence"

}

getsshpass(){
  read -sp 'Enter the iDRAC root password: ' SSHPASS; 
  export SSHPASS;
  printf '\n';
}

dosetpxe(){
for RACADM in \
  "set iDRAC.serverboot.BootOnce 1" \
  "set iDRAC.serverboot.FirstBootDevice PXE"; do
    for RNAME in ${NAMERANGE[*]};do
      printf '\n'
      DRACFQDN=$RNAME.$MGTLAN.$SITE.${DOMAIN%.}
      egrep -q "$LIMITERE" <<< $DRACFQDN || continue
      doracadm "$RACADM" $DRACFQDN
    done
done
}

dopowercycle(){
for RACADM in \
  "serveraction powercycle"; do
    for RNAME in ${NAMERANGE[*]};do
      printf '\n'
      DRACFQDN=$RNAME.$MGTLAN.$SITE.${DOMAIN%.}
      egrep -q "$LIMITERE" <<< $DRACFQDN || continue
      [[ $FLAGS =~ f ]] || {
        echo -e "Pausing for $TIMEOUT before fail exit: [s]kip target or any other
        key to proceed to '$RACADM' on $DRACFQDN"
        read -t$TIMEOUT -sn1
        printf '\n'
        case $REPLY in
          s) continue ;;
        esac
      }
      doracadm "$RACADM" $DRACFQDN
    done
done
}

dowaitandauth(){
# manage $USER's known_hosts and install the SSH public key for each target
for RNAME in ${NAMERANGE[*]}; do
  for FQDN in $RNAME.$DSTLAN.$SITE.$DOMAIN; do
    egrep -q "$LIMITERE" <<< $FQDN || continue
    printf "Waiting for $FQDN:22..."
    until nc -w1 $FQDN 22 </dev/null &>/dev/null; do
      sleep 9;printf '.';
    done
    printf '\n'
    ssh-keygen -F $FQDN &>/dev/null && { 
      ssh-keygen -R $FQDN 
    } || {
      true
    }
    [[ $FLAGS =~ i ]] || sshpass -e \
      ssh-copy-id -o StrictHostKeyChecking=no root@$FQDN
  done
done
}

# configuration
NAMERANGE=('hyp'{001..003}) # short name(s) of the hosts (not iDRACs)
MGTLAN='mgt400' # the DNS label of the VLAN where the iDRAC is homed and the
                # device name of the interface
KICKLAN=('oob001' 'em1') # DNS label of the VLAN for PXE and the device name
DSTLAN=('inf412' 'em2.412') # DNS label of the host's destination VLAN
SITE="vdc1" # DNS label of the physical site or geographic locale
DOMAIN="example.com" # DNS namespace of the realm

# defaults
TIMEOUT=999 # pause for -t <seconds> before destructive changes
LIMITERE='.*' # limit operations to hosts that match -l <exetended regex>
FLAGS=''

while getopts 'fvt:l:wi' OPT;do
  case $OPT in
    f) FLAGS+=$OPT ;; # -f don't pause
    v) FLAGS+=$OPT ;; # -v print the kicksheet 
    t) TIMEOUT="$OPTARG" ;; # -t <seconds> to stagger powercycle 
    l) LIMITERE="$OPTARG" ;; # operate only on targets matching extended regex
    w) FLAGS+=$OPT ;; # don't reboot, just wait for tcp ping and authorize key
    i) FLAGS+=$OPT ;; # don't install
  esac
done

# main
# get pass if unset
[[ -z ${SSHPASS+nil} ]] && getsshpass

# optionally print the kicksheet
[[ $FLAGS =~ v ]] && kicksheet

# reboot unless skip is set
if [[ ! $FLAGS =~ w ]];then
  dosetpxe
  dopowercycle
fi

# wait for install, import new host keys, authorize key for root
dowaitandauth

