#!/bin/bash
clear
# -------------------------------------------------------------
# Michael Eichinger, BSc
# Release: v 1.0
# Date: 28.04.2019
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
raspi_ip="10.0.0.24" # this ist the first honeypot
raspi_pubip="192.168.1.24"
raspi_net_mask="24"
raspi_pubnet_mask="24"
raspi_gateway="10.0.0.1"
raspi_pubgateway="192.168.1.1"
raspi_dns='208.67.222.222 208.67.220.220'
echo "###############################################"
echo "Installations-Script         Version 2019-03-26"
echo "Copyright Michael Eichinger                2019"
echo "###############################################"
echo "Cowrie Honeypot wird eingerichtet:"
echo "   Der Vorgang kann mehrere Minuten dauern, bitte um Geduld!"
echo " "
# ########################################
# edit SSH Banner
rm /etc/ssh/ssh-banner-glastopf.txt
cp ~/APT-Detection/glastopf/ssh-banner-glastopf.txt /etc/ssh/
echo " - SSH Banner wurde erstellt"
cat /etc/ssh/ssh-banner-glastopf.txt
sed -i 's/#Banner none/Banner \/etc\/ssh\/ssh-banner-cowrie.txt/g' /etc/ssh/sshd_config
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
# change hostname
sed -i 's/raspberrypi/glastopf/g' /etc/hostname
sed -i 's/raspberrypi/glastopf/g' /etc/hosts
echo -e "\n- IP Adressen und Hostname wurden geändert"
# -------------------------------------------------------------
# Step 2) install glastopf honeypot software
# -------------------------------------------------------------
#
apt-get update
apt-get install python python-openssl python-gevent libevent-dev build-essential -y


echo -e "\n- Glastopf WebApplikation Honeypot wurde installiert"

# -------------------------------------------------------------
# Step 3) config filebeat
# -------------------------------------------------------------
cp ~/APT-Detection/glastopf/filebeat.yml /etc/filebeat/
cp ~/APT-Detection/glastopf/lib/systemd/system/filebeat.service /lib/systemd/system/
echo -e "\n- Konfiguration für Filebeat Glastopf LogDateien wurde eingerichtet"
cat /etc/filebeat/filebeat.yml
systemctl enable filebeat.service
service filebeat start
sleep 3
service filebeat status
echo -e "\n- Filebeat Installation ist abgeschlossen"
# finish
apt autoremove -y
echo -e "\n- Installation wurde bereinigt"
# login as cowrie user to install the software
echo -e "\n- GLASTOPF Honeypot Konfiguration wurde abgeschlossen!"
echo -e "\n"
echo -e "\n zur finalen Endinstallation sind folgende Befehle erforderlich:"
echo -e "\n"
echo -e "\n"
echo -e "\n nach einem finalen Reboot kann Glastopf fertig eingesetzt werden"
echo -e "\n"

