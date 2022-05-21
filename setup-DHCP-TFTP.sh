#!/bin/bash

# Obligatorios
NODE_HOSTNAME=$1
NODE_IP=$2
MAC=$3

NODE_BOOTIF=eth0
BOOT_FILE=pxelinux.0
HTTP_EXE=busybox_HTTPD
NET_IFNAMES=net.ifnames=0
NETBOOT_IFACE=eth0
NETBOOT_SERVER=172.17.2.2
NETBOOT_BROADCAST=172.17.0.0
NETBOOT_NETMASK=255.255.0.0
NETBOOT_GATEWAY=172.17.1.1
NETBOOT_DNS=8.8.8.8
NETBOOT_ROOT=$PWD
NETBOOT_CONSOLE="selinux=0 inst.text inst.sshd console=tty0 console=ttyS1,115200n8"
NETBOOT_KERNEL=/x86_64/images/pxeboot/vmlinuz
NETBOOT_INITRD=/x86_64/images/pxeboot/initrd.img

_gen-KS(){
NODE_IB=$(echo $NODE_IP | awk -F. '{print $1"."$2+2"."$3"."$4}')
echo "# Network information
network  --bootproto=static --device=$NODE_BOOTIF --gateway=$NETBOOT_GATEWAY --ip=$NODE_IP --nameserver=$NETBOOT_DNS --netmask=$NETBOOT_NETMASK --noipv6 --activate
network  --bootproto=static --device=ib0  --ip=$NODE_IB  --netmask=$NETBOOT_NETMASK --noipv6 --activate
network  --bootproto=dhcp --device=eth1 --onboot=off --ipv6=auto
network  --bootproto=dhcp --device=eth2 --onboot=off --ipv6=auto
network  --hostname=$NODE_HOSTNAME
" >  $NETBOOT_ROOT/kickstart.cfg/$NODE_HOSTNAME
cat  $NETBOOT_ROOT/default.kickstart >> $NETBOOT_ROOT/kickstart.cfg/$NODE_HOSTNAME 

}

_gen-PXE(){

echo "default install
label install
        KERNEL $NETBOOT_KERNEL 
        APPEND initrd=$NETBOOT_INITRD ip=$NODE_IP::$NETBOOT_GATEWAY:$NETBOOT_NETMASK:$NODE_HOSTNAME:$NODE_BOOTIF:none  nameserver=$NETBOOT_DNS  modprobe.blacklist=rndis_host,cdc_ether inst.repo=http://$NETBOOT_SERVER/x86_64/ inst.ks=http://$NETBOOT_SERVER/kickstart.cfg/$NODE_HOSTNAME inst.loglevel=debug --- $NETBOOT_CONSOLE $NET_IFNAMES  " > $NETBOOT_ROOT/nodes.cfg/$NODE_HOSTNAME

echo "serial 1 115200 0
include /nodes.cfg/$NODE_HOSTNAME" > $NETBOOT_ROOT/pxelinux.cfg/$NODE_HOSTNAME

ln -sfv $NETBOOT_ROOT/pxelinux.cfg/$NODE_HOSTNAME  $NETBOOT_ROOT/pxelinux.cfg/01-$(echo $MAC | tr ":" "-")
ln -sfv $NETBOOT_ROOT/pxelinux.cfg/$NODE_HOSTNAME  $NETBOOT_ROOT/pxelinux.cfg/$( printf "%02X" $(echo $NODE_IP | tr "." " " ) )

}


_gen-DHCP(){

test ! -e $NETBOOT_ROOT/dnsmasq.cfg/global.conf  && echo "leasefile-ro 
no-hosts 
log-queries 
no-daemon 
no-resolv 
no-poll
port=0 
log-dhcp 
enable-tftp 
tftp-unique-root 
dhcp-boot=$BOOT_FILE 
dhcp-leasefile=/dev/null 
interface=$NETBOOT_IFACE 
dhcp-range=$NETBOOT_BROADCAST,static 
tftp-root=$NETBOOT_ROOT
dhcp-option=option:router,$NETBOOT_GATEWAY 
dhcp-option=option:dns-server,$NETBOOT_DNS 
" > $NETBOOT_ROOT/dnsmasq.cfg/global.conf 

test ! -e $NETBOOT_ROOT/run-DNSMASQ.sh && echo "#!/bin/bash 
sudo pkill dnsmasq
sudo pkill $HTTP_EXE 
sudo $NETBOOT_ROOT/$HTTP_EXE -h $NETBOOT_ROOT
sudo dnsmasq --conf-dir=$NETBOOT_ROOT/dnsmasq.cfg 
" > $NETBOOT_ROOT/run-DNSMASQ.sh 

echo "dhcp-host=$MAC,$NODE_HOSTNAME,$NODE_IP,1h" >  $NETBOOT_ROOT/dnsmasq.cfg/$NODE_HOSTNAME

}

test -z $1  && echo "falta datos del servidor:  node1 172.17.2.1 3c:ec:ef:18:d6:aa " && exit
test ! -e $NETBOOT_ROOT/$BOOT_FILE && echo "falta archivo $NETBOOT_ROOT/$BOOT_FILE " && exit 1 
test ! -e $NETBOOT_ROOT/$HTTP_EXE && echo "falta archivo $NETBOOT_ROOT/$HTTP_EXE " && exit 1 
test ! -d $NETBOOT_ROOT/pxelinux.cfg && mkdir -v $NETBOOT_ROOT/pxelinux.cfg 
test ! -d $NETBOOT_ROOT/nodes.cfg && mkdir -v $NETBOOT_ROOT/nodes.cfg
test ! -d $NETBOOT_ROOT/kickstart.cfg && mkdir -v $NETBOOT_ROOT/kickstart.cfg 
test ! -d $NETBOOT_ROOT/dnsmasq.cfg && mkdir -v $NETBOOT_ROOT/dnsmasq.cfg 

_gen-PXE 
_gen-KS
_gen-DHCP


echo "
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ejecutar: 

bash $NETBOOT_ROOT/run-DNSMASQ.sh 

y encender nodo en arranque PXE para comenzar instalación 

NETBOOT_SERVER=$NETBOOT_SERVER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
