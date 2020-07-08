#!/bin/bash
clear
# -------------------------------------------------------------
# Dipl.-Ing. Michael Eichinger, BSc
# Release: v 1.0
# Date: 08.07.2020
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
raspi_ip="10.0.0.50" # this ist the first honeypot
raspi_pubip="192.168.1.50"
raspi_net_mask="24"
raspi_pubnet_mask="24"
raspi_gateway="10.0.0.1"
raspi_pubgateway="192.168.1.1"
raspi_dns='208.67.222.222 208.67.220.220'
echo "###############################################"
echo "Installations-Script         Version 2020-07-08"
echo "Copyright Michael Eichinger                2020"
echo "###############################################"
echo "WLAN-Bridge wird eingerichtet:"
echo "   Der Vorgang kann mehrere Minuten dauern, bitte um Geduld!"
echo " "
# ########################################
# edit SSH Banner
rm /etc/ssh/ssh-banner-wlanbrdige.txt
cp ~/APT-Detection/wlanbridge/ssh-banner-wlanbridge.txt /etc/ssh/
echo " - SSH Banner wurde erstellt"
cat /etc/ssh/ssh-banner-wlanbridge.txt
sed -i 's/#Banner none/Banner \/etc\/ssh\/ssh-banner-wlanbridge.txt/g' /etc/ssh/sshd_config
sed -i 's/ListenAddress 0.0.0.0/ListenAddress '$raspi_ip'/g' /etc/ssh/sshd_config
# ########################################
# update IP address
#
echo " - IP Adresse wird angepasst"
cp /etc/dhcpcd.conf /etc/dhcpcd.conf.orig
sed -i 's/static ip_address=10.0.0.30\/24/static ip_address='$raspi_ip'\/'$raspi_net_mask'/g' /etc/dhcpcd.conf
#echo 'interface eth1' >> /etc/dhcpcd.conf
#echo 'static ip_address='$raspi_pubip'/'$raspi_pubnet_mask >> /etc/dhcpcd.conf
#echo 'static routers='$raspi_pubgateway >> /etc/dhcpcd.conf
echo 'static domain_name_servers='$raspi_dns >> /etc/dhcpcd.conf
echo -e "\n- fixe" $raspi_ip " Management IP Adresse wurde eingerichtet"
echo -e "\n- fixe" $raspi_pubip " LAN IP Adresse wurde eingerichtet"
# change hostname
sed -i 's/raspberrypi/cowrie/g' /etc/hostname
sed -i 's/raspberrypi/cowrie/g' /etc/hosts
echo -e "\n- IP Adressen und Hostname wurden geaendert"
# -------------------------------------------------------------
# Step 2) config filebeat
# -------------------------------------------------------------
# only if it is necessary
#cp ~/APT-Detection/cowrie/filebeat.yml /etc/filebeat/
#cp ~/APT-Detection/cowrie/lib/systemd/system/filebeat.service /lib/systemd/system/
echo -e "\n- Konfiguration fuer Filebeat Cowrie LogDateien wurde eingerichtet"
cat /etc/filebeat/filebeat.yml
systemctl enable filebeat.service
service filebeat start
sleep 3
service filebeat status
echo -e "\n- Filebeat Installation ist abgeschlossen"
# finish
apt autoremove -y
echo -e "\n- Installation wurde bereinigt"
echo -e "\n"
echo -e "\n nach einem finalen Reboot kann die WLAN-Bridge eingesetzt werden"
echo -e "\n"

