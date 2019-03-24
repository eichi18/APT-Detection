# -------------------------------------------------------------
# Step 1) change the static ip-address
# -------------------------------------------------------------
if [ $(id -u) -ne 0 ]; then
  printf "This script must be run as root. \n"
  exit 1
fi
# ########################################
# set parameter for this honeypot
#
raspi_ip="10.0.0.41" # this ist the first honeypot
raspi_pubip="192.168.1.41"
raspi_net_mask="24"
raspi_pubnet_mask="24"
raspi_gateway="10.0.0.1"
raspi_pubgateway="192.168.1.1"
raspi_dns='208.67.222.222 208.67.220.220'
echo "###############################################"
echo "Installations-Script         Version 2019-03-23"
echo "Copyright Michael Eichinger                2019"
echo "###############################################"
echo "Dionaea Honeypot wird eingerichtet:"
echo "   Der Vorgang kann mehrere Minuten dauern, bitte um Geduld!"
echo " "
# ########################################
# edit SSH Banner
rm /etc/ssh/ssh-banner-cowrie.txt
cp ~/APT-Detection/ssh-banner-cowrie.txt /etc/ssh/
echo " - SSH Banner wurde erstellt"
cat /etc/ssh/ssh-banner-dionaea.txt
sed -i 's/#Banner none/Banner \/etc\/ssh\/ssh-banner-dionaea.txt/g' /etc/ssh/sshd_config
sed -i 's/ListenAddress 0.0.0.0/ListenAddress '$raspi_pubip'/g' /etc/ssh/sshd_config
# ########################################
# update IP Adress
#
echo " - IP Adresse wird angepasst"
cp /etc/dhcpcd.conf /etc/dhcpcd.conf.orig
sed -i 's/static ip_address=10.0.0.30\/24/static ip_address='$raspi_ip'/g' /etc/dhcpcd.conf
echo 'interface eth1' >> /etc/dhcpcd.conf
echo 'static ip_address='$raspi_pubip'/'$raspi_pubnet_mask >> /etc/dhcpcd.conf
echo 'static routers='$raspi_pubgateway >> /etc/dhcpcd.conf
echo 'static domain_name_servers='$raspi_dns >> /etc/dhcpcd.conf
echo -e "\n- fixe" $raspi_pubip " Management IP Adresse wurde eingerichtet"
echo -e "\n- fixe" $raspi_ip " LAN IP Adresse wurde eingerichtet"
echo -e "\n- Konfiguration wurde abgeschlossen!"
# change hostname
sed -i 's/raspberrypi/dionaea/g' /etc/hostname
sed -i 's/raspberrypi/dionaea/g' /etc/hosts
# -------------------------------------------------------------
# Step 2) install dionaea
# -------------------------------------------------------------
# ########################################
#  install dionaea honeypot
echo "deb http://packages.s7t.de/raspbian wheezy main" >> /etc/apt/sources.list
apt-get update
apt-get install libglib2.0-dev libssl-dev libcurl4-openssl-dev libreadline-dev libsqlite3-dev libtool automake -y
apt-get install autoconf build-essential subversion git-core flex bison pkg-config libnl-3-dev libnl-genl-3-dev -y
apt-get install libnl-nf-3-dev libnl-route-3-dev liblcfg libemu libev dionaea-python dionaea-cython libpcap -y
apt-get install udns dionaea liblcfg -y
cp /opt/dionaea/etc/dionaea/dionaea.conf.dist /opt/dionaea/etc/dionaea/dionaea.conf
chown nobody:nogroup /opt/dionaea/var/dionaea -R
echo -e "\n- IP Adressen wurden geändert"

# -------------------------------------------------------------
# Step 3) install Filebeat for Raspberry Pi
# -------------------------------------------------------------
cd ~/APT-Detection/
mkdir /etc/filebeat
file="/root/APT-Detection/filebeat/filebeat-6.6.0-linux-x86.tar.gz"
if [ -f "$file" ];
then
    # File exist!
    tar -xf ~/APT-Detection/filebeat/filebeat-6.6.0-linux-x86.tar.gz -C /etc/filebeat
    echo -e "\n- Filebeat wurde enpackt und nach /etc/filebeat kopiert"
else
    # File doese not exist
    cd ~
    git clone https://github.com/eichi18/APT-Detection.git
    tar -xf ~/APT-Detection/filebeat/filebeat-6.6.0-linux-x86.tar.gz -C /etc/filebeat
    echo -e "\n- Filebeat wurde von GitHub geladen, enpackt und nach /etc/filebeat kopiert"
fi
mkdir /usr/share/filebeat
mkdir /usr/share/filebeat/bin
mkdir /var/log/filebeat
mkdir /var/lib/filebeat
cp /etc/filebeat/filebeat /usr/share/filebeat/bin/
chmod 750 /var/log/filebeat
chmod 750 /etc/filebeat/
chown -R root:root /usr/share/filebeat/*
cp -r /etc/filebeat/module /usr/share/filebeat/
echo -e "\n- Filebeat wurde installiert"

