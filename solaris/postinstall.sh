#/usr/bin/bash
#set -e
set -x

VBOXRELEASE=4.1.8

#[ -L /usr/bin/make ] && rm /usr/bin/make
#[ -L /usr/bin/make ] || ln -s /opt/csw/bin/gmake /usr/bin/make
MAKE=/opt/csw/bin/gmake
export MAKE
date > /etc/vagrant_box_build_time

echo vagrant-sol10_8-11 > /etc/nodename

# Add the opencsw package site
PATH=/usr/bin:/usr/sbin:/opt/csw/sbin:/opt/csw/bin
export PATH

yes|/usr/sbin/pkgadd -d http://mirror.opencsw.org/opencsw/pkgutil-`uname -p`.pkg all

# Setup correct mirror heanet

cat > /etc/opt/csw/pkgutil.conf <<EOF
mirror=http://ftp.heanet.ie/pub/opencsw/current
mirror=http://debs.ugent.be/solaris/
noncsw=true
use_md5=true
use_gpg=false
pkgaddopts=-G
EOF

/opt/csw/bin/pkgutil -U

# We need some header stuff and so on to get gcc going
# Tip thx to - https://wiki.chipp.ch/twiki/bin/view/CmsTier3/InstallationSolaris
#/usr/bin/pkg install SUNWarc SUNWsfwhea SUNWhea SUNWtoo
#/usr/bin/pkg install math/header-math

/opt/csw/bin/pkgutil -y -i CSWgsed
/opt/csw/bin/pkgutil -y -i CSWgmake
/opt/csw/bin/pkgutil -y -i CSWruby18
/opt/csw/bin/pkgutil -y -i CSWruby18-dev
/opt/csw/bin/pkgutil -y -i CSWrubygems

# These are needed to get a compiler working
# Mainly because chef depends on compiling some native gems
export PATH=/opt/csw/bin:$PATH
export PATH=/opt/csw/gcc4/bin:$PATH

/opt/csw/bin/pkgutil -y -i CSWgcc4core

/opt/csw/bin/pkgutil -y -i CSWsudo

/opt/csw/bin/pkgutil -y -i CSWgcc4g++
/opt/csw/bin/pkgutil -y -i CSWreadline
/opt/csw/bin/pkgutil -y -i CSWzlib
/opt/csw/bin/pkgutil -y -i CSWossldevel

# prevents ":in `require': no such file to load -- mkmf (LoadError)"
# yes|/opt/csw/bin/pkgutil -i CSWruby
# used SUNWspro
# has entries in /opt/csw/lib/ruby/1.8/i386-solaris2.9/rbconfig.rb
# luckily there is another one
# For some reason these don't get installed ok, we need to give them a slight kick again
/opt/csw/bin/pkgutil -y -i CSWruby18-gcc4

# no solaris2.11 .... mkheaders here ! needs some fixing ??
/opt/csw/gcc4/libexec/gcc/i386-pc-solaris2.10/4.3.3/install-tools/mkheaders
#/opt/csw/gcc4/libexec/gcc/i386-pc-solaris2.8/4.3.3/install-tools/mkheaders 

#/opt/csw/sbin/alternatives --display rbconfig18
/opt/csw/sbin/alternatives --set rbconfig18 /opt/csw/lib/ruby/1.8/i386-solaris2.9/rbconfig.rb.gcc4

/opt/csw/bin/gem install puppet  --no-ri --no-rdoc
/opt/csw/bin/gem install chef  --no-ri --no-rdoc
getent group puppet || groupadd puppet

#Installing vagrant user and keys
useradd -d /export/home/vagrant vagrant
mkdir -p /export/home/vagrant/.ssh
chmod 700 /export/home/vagrant/.ssh
/usr/sfw/bin/wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O /export/home/vagrant/.ssh/authorized_keys
chown -R vagrant /export/home/vagrant

/opt/csw/bin/gsed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
[ -d /.ssh ] || mkdir /.ssh
/usr/sfw/bin/wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O /.ssh/authorized_keys

#Installing the virtualbox guest additions
# Delete old version
yes | /usr/sbin/pkgrm SUNWvboxguest
cd /tmp
mkdir virtualbox && cd virtualbox
/usr/sfw/bin/wget http://download.virtualbox.org/virtualbox/${VBOXRELEASE}/VBoxGuestAdditions_${VBOXRELEASE}.iso
lofiadm -a /tmp/virtualbox/VBoxGuestAdditions_${VBOXRELEASE}.iso /dev/lofi/1
mount -F hsfs -o ro /dev/lofi/1 /mnt/  
cd /mnt
yes | pkgadd -d VBoxSolarisAdditions.pkg all
cd /
umount /mnt && lofiadm -d /dev/lofi/1
rm -fr /tmp/virtualbox


# Some info on how to setup virtualbox on solaris
#/usr/sfw/bin/wget http://download.virtualbox.org/virtualbox/4.1.8/VirtualBox-4.1.8-75467-SunOS.tar.gz
#gunzip VirtualBox-4.1.8-75467-SunOS.tar.gz
#tar xf VirtualBox-4.1.8-75467-SunOS.tar
#/usr/bin/pkgtrans VirtualBox-4.1.8-SunOS-r75467.pkg . all
#yes|/usr/sbin/pkgadd -d . SUNWvbox

# Setup sudo
grep '%other ALL=NOPASSWD: ALL' /opt/csw/etc/sudoers || echo '%other ALL=NOPASSWD: ALL' >> /opt/csw/etc/sudoers
chmod 0440 /opt/csw/etc/sudoers

# sudo through ssh doesn't work otherwise
grep 'PATH=/usr/sbin:/usr/bin:/opt/csw/bin:/opt/csw/sbin' /etc/default/login || echo 'PATH=/usr/sbin:/usr/bin:/opt/csw/bin:/opt/csw/sbin' >> /etc/default/login

# Set profile

cat > /export/home/vagrant/.profile <<EOF
PATH=/usr/bin:/opt/csw/bin
export PATH
EOF
chown vagrant:other /export/home/vagrant/.profile

cat > /.profile <<EOF
PATH=/usr/bin:/usr/sbin:/opt/csw/bin:/opt/csw/sbin
export PATH
EOF

echo "Note: validation of this box wil fail, as it's not linux based, working on that"

#[ -L /usr/bin/make ] && rm /usr/bin/make

rm -fr /tmp/*

mkdir /vagrant
exit
