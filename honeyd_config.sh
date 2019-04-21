#!/bin/bash
clear
# -------------------------------------------------------------
# Michael Eichinger, BSc
# Release: v 0.2
# Date: 21.04.2019
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
raspi_ip="10.0.0.22" # this ist the first honeypot
raspi_pubip="192.168.1.22"
raspi_net_mask="24"
raspi_pubnet_mask="24"
raspi_gateway="10.0.0.1"
raspi_pubgateway="192.168.1.1"
raspi_dns='208.67.222.222 208.67.220.220'
echo "###############################################"
echo "Installations-Script         Version 2019-04-21"
echo "Copyright Michael Eichinger                2019"
echo "###############################################"
echo "Honeyd Honeypot wird eingerichtet:"
echo "   Der Vorgang kann mehrere Minuten dauern, bitte um Geduld!"
echo " "
# ########################################
# edit SSH Banner
rm /etc/ssh/ssh-banner-honeyd.txt
cp ~/APT-Detection/honeyd/ssh-banner-honeyd.txt /etc/ssh/
echo " - SSH Banner wurde erstellt"
cat /etc/ssh/ssh-banner-honeyd.txt
sed -i 's/#Banner none/Banner \/etc\/ssh\/ssh-banner-honeyd.txt/g' /etc/ssh/sshd_config
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
sed -i 's/raspberrypi/honeyd/g' /etc/hostname
sed -i 's/raspberrypi/honeyd/g' /etc/hosts
echo -e "\n- IP Adressen und Hostname wurden geändert"
# -------------------------------------------------------------
# Step 2) install honeyd honeypot software
# -------------------------------------------------------------
apt-get updade -y
# download the honeyd software
git clone https://github.com/DataSoft/Honeyd.git /usr/src/Honeyd/
cd  /usr/src
# install required build dependencies before configuring and building honeyd
apt-get install libdnet libevent-dev libdumbnet-dev libpcap-dev libpcre3-dev -y
apt-get install libedit-dev bison flex libtool automake -y
# install honeyd software
cd Honeyd
./autogen.sh
./configure
make
make install
# logging
mkdir /var/log/honeyd
# install farpd
apt-get install farpd -y
rm /etc/init.d/farpd
cp /root/APT-Detection/honeyd/etc/systemd/system/farpd.service /etc/systemd/system/
chmod 644 /etc/systemd/system/farpd.service
systemctl daemon-reload
systemctl enable farpd.service
systemctl start farpd.service
# copy the config
cp /root/APT-Detection/honeyd/usr/src/Honeyd/honeyd.conf /usr/src/Honeyd/honeyd.conf
# starting as service and autostart
cp /root/APT-Detection/honeyd/etc/systemd/system/honeyd.service /etc/systemd/system/
chmod 644 /etc/systemd/system/honeyd.service
systemctl daemon-reload
systemctl enable honeyd.service
systemctl start honeyd.service
echo -e "\n- Dionaea Honeypot Konfiguration wurde abgeschlossen!"
echo -e "\n"
echo -e "\n nach einem finalen Reboot kann Dionaea fertig eingesetzt werden"
# -------------------------------------------------------------
# Step 3) config filebeat
# -------------------------------------------------------------
cp ~/APT-Detection/honeyd/etc/filebeat/filebeat.yml /etc/filebeat/
cp ~/APT-Detection/honeyd/lib/systemd/system/filebeat.service /lib/systemd/system/
echo -e "\n- Konfiguration für Filebeat Cowrie LogDateien wurde eingerichtet"
cat /etc/filebeat/filebeat.yml
systemctl enable filebeat.service
service filebeat start
sleep 3
service filebeat status
echo -e "\n- Filebeat Installation ist abgeschlossen"
