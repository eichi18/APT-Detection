#!/bin/bash
clear
# -------------------------------------------------------------
# Michael Eichinger, BSc
# Release: v 1.0
# Date: 26.03.2019
# Email: office@eichinger.co.at
# NOTE: installation script
# Startin position is Raspberry Pi 2 or 3 with brand new
# installation
# Image: Stretch 13.11.2018
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
raspi_ip="10.0.0.21" # this ist the first honeypot
raspi_pubip="192.168.1.21"
raspi_net_mask="24"
raspi_pubnet_mask="24"
raspi_gateway="10.0.0.1"
raspi_pubgateway="192.168.1.1"
raspi_dns='208.67.222.222 208.67.220.220'
echo "###############################################"
echo "Installations-Script         Version 2019-03-26"
echo "Copyright Michael Eichinger                2019"
echo "###############################################"
echo "Dionaea Honeypot wird eingerichtet:"
echo "   Der Vorgang kann mehrere Minuten dauern, bitte um Geduld!"
echo " "
# ########################################
# edit SSH Banner
rm /etc/ssh/ssh-banner-cowrie.txt
cp ~/APT-Detection/dionaea/ssh-banner-dionaea.txt /etc/ssh/
echo " - SSH Banner wurde erstellt"
cat /etc/ssh/ssh-banner-dionaea.txt
sed -i 's/#Banner none/Banner \/etc\/ssh\/ssh-banner-dionaea.txt/g' /etc/ssh/sshd_config
sed -i 's/ListenAddress 0.0.0.0/ListenAddress '$raspi_ip'/g' /etc/ssh/sshd_config
# ########################################
# update IP address
#
echo " - IP Adresse wird angepasst"
cp /etc/dhcpcd.conf /etc/dhcpcd.conf.orig
sed -i 's/static ip_address=10.0.0.30\/24/static ip_address='$raspi_ip'/g' /etc/dhcpcd.conf
echo 'interface eth1' >> /etc/dhcpcd.conf
echo 'static ip_address='$raspi_pubip'/'$raspi_pubnet_mask >> /etc/dhcpcd.conf
echo 'static routers='$raspi_pubgateway >> /etc/dhcpcd.conf
echo 'static domain_name_servers='$raspi_dns >> /etc/dhcpcd.conf
echo -e "\n- fixe" $raspi_ip " Management IP Adresse wurde eingerichtet"
echo -e "\n- fixe" $raspi_pubip " LAN IP Adresse wurde eingerichtet"
echo -e "\n- Konfiguration wurde abgeschlossen!"
# change hostname
sed -i 's/raspberrypi/dionaea/g' /etc/hostname
sed -i 's/raspberrypi/dionaea/g' /etc/hosts
echo -e "\n- IP Adressen und Hostname wurden geändert"
# -------------------------------------------------------------
# Step 2) install dionaea honeypot software
# -------------------------------------------------------------
#
# source: https://dionaea.readthedocs.io/en/latest/installation.html
# downloading source code of dionaea
# install kernel headers
apt-get install raspberrypi-kernel-headers
# download the dionaea software
git clone --depth=1 https://github.com/DinoTools/dionaea.git -b 0.8.0 /root/dionaea/ 
cd  /root/dionaea
# install required build dependencies before configuring and building dionaea
apt-get install build-essential cmake check cython3 libcurl4-openssl-dev libemu-dev libev-dev -y
apt-get install libglib2.0-dev libloudmouth1-dev libnetfilter-queue-dev libnl-3-dev libpcap-dev -y
apt-get install libssl-dev libtool libudns-dev python3 python3-dev python3-bson python3-yaml -y
apt-get install python3-boto3 ttf-liberation -y
# create a build dictory and run cmake to setup the build process
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=/opt/dionaea ..
# run make to build and run make install to install the honeypot
make
make install
cp /opt/dionaea/etc/dionaea/dionaea.cfg /opt/dionaea/etc/dionaea/dionaea.cfg.dist
# creat dionaea user
adduser --disabled-password --gecos "" dionaea
chown dionaea:dionaea -R /opt/dionaea/
echo -e "\n- Dionaea wurde installiert"
# install ntp service
apt-get install ntp -y
# starting as service and autostart
cp /root/APT-Detection/dionaea/etc/systemd/system/dionaea.service /etc/systemd/system/
chmod 644 /etc/systemd/system/dionaea.service
systemctl daemon-reload
systemctl start dionaea.service

# config for filebeat
cp ~/APT-Detection/dionaea/filebeat.yml /etc/filebeat/
echo -e "\n- Konfiguration für Filebeat Dionaea LogDateien wurde eingerichtet"
cat /etc/filebeat/filebeat.yml
systemctl enable filebeat.service
service filebeat start
sleep 3
service filebeat status
echo -e "\n- Dionaea Honeypot Konfiguration wurde abgeschlossen!"
echo -e "\n"
echo -e "\n nach einem finalen Reboot kann Dionaea fertig eingesetzt werden"
