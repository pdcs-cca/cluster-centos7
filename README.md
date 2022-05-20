# cluter-centos7
Script y archivo kickstart para instalación por red del SO CentOS 7

Requiere de busubox http  y mirror de la instalación

~~~bash
git clone https://github.com/pdcs-cca/cluster-centos7.git
cd cluster-centos7
curl -LO https://www.busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox_HTTPD
chmod +x busybox_HTTPD
~~~

## RSYNC
~~~bash
 MIRROR=rsync://mirror.facebook.net/centos/7.9.2009/os/x86_64
 rsync -Pa $MIRROR .
~~~

## WGET
~~~bash
MIRROR=http://mirror.facebook.net/centos/7.9.2009/os/x86_64
# wget --mirror  --no-clobber --no-host-directories --convert-links --adjust-extension  --no-parent $MIRROR
#--mirror -m 
#--no-clobber -nc
#--no-host-directories -nH
#--convert-links -k
#--no-parent -np
#--adjust-extension -E 
wget -m -nc -nH -k -np -E  $MIRROR
~~~

bash setup-DHCP-TFTP.sh
