#!/bin/bash
clear
# -------------------------------------------------------------
# Michael Eichinger, BSc
# Release: v 0.3
# Date: 09.01.20198
# Email: office@eichinger.co.at
# NOTE: installation script
# Startin position is Raspberry Pi 2 or 3 with brand new
# installation
# Image: Stretch 27.06.2018
# -------------------------------------------------------------
# Step 1) base configuration
# -------------------------------------------------------------
if [ $(id -u) -ne 0 ]; then
  printf "This script must be run as root. \n"
  exit 1
fi
# ########################################
# set parameter for this honeypot
raspi_ip="10.0.0.30"
raspi_net_mask="24"
raspi_gateway="10.0.0.1"
raspi_dns='208.67.222.222 208.67.220.220'
echo "###############################################"
echo "Installations-Script         Version 2018-01-10"
echo "Copyright Michael Eichinger                2019"
echo "###############################################"
echo "Raspberry Pi Grundkonfiguration wird eingerichtet:"
echo "   Der Vorgang kann mehrere Minuten dauern, bitte um Geduld!"
echo " "
# ########################################
# richte Zeitzone ein
echo "Europe/Vienna" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata > /dev/null 2> /dev/null
date +%Z | egrep -q "^CE(S){0,1}T$" > /dev/null 2> /dev/null && echo "- Zeitzone wurde eingerichtet." || echo "FEHLER: Zeitzone konnte nicht eingerichtet werden!"
# ########################################
# aktualisiere Systemzeit
# https://wiki.archlinux.org/index.php/Systemd-timesyncd
echo "------------------------------------------------"
echo "        aktuelle Zeit:"
echo "------------------------------------------------"
timedatectl status
echo "------------------------------------------------"
#
# ########################################
# richte Sprache ein
#sed -i 's/en_GB.UTF-8 UTF-8/# en_GB.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/# de_AT.UTF-8 UTF-8/de_AT.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen > /dev/null 2> /dev/null
update-locale LANG=de_AT.UTF-8 LANGUAGE=de_AT:de > /dev/null 2> /dev/null && echo "- Sprache wurde eingerichtet." || echo "FEHLER: Sprache konnte nicht eingerichtet werden!"
# ########################################
# richte Tastaturlayout ein (Danke an https://github.com/shamiao/TRUNCATED-raspbian-zhcn-customized/blob/master/construct.sh)
sed -i 's/XKBLAYOUT=gb/XKBLAYOUT=at/g' /etc/default/keyboard
dpkg-reconfigure --frontend=noninteractive keyboard-configuration > /dev/null 2> /dev/null
invoke-rc.d keyboard-setup start > /dev/null 2> /dev/null
debconf-get-selections | grep "xkb-keymap" | grep "at" > /dev/null 2> /dev/null && echo "- Tastaturlayout wurde eingerichtet." || echo "FEHLER: Tastaturlayout konnte nicht eingerichtet wer108.67.222.222 208.67.220.220 ' /etc/dhcpcd.conf
den!"
# ########################################
# richte IP Adresse einrichten
cp /etc/dhcpcd.conf /etc/dhcpcd.conf.orig
rm /etc/dhcpcd.conf
touch /etc/dhcpcd.conf
echo 'interface eth0' >> /etc/dhcpcd.conf
echo 'static ip_address='$raspi_ip'/'$raspi_net_mask >> /etc/dhcpcd.conf
echo 'static routers='$raspi_gateway >> /etc/dhcpcd.conf
echo 'static domain_name_servers='$raspi_dns >> /etc/dhcpcd.conf
echo -e "\n-fixe" $raspi_ip " IP Adresse wurde eingerichtet"
# ++++++++-----------------------------------------------------
# Step 2) software depoloyment
# -------------------------------------------------------------
# ########################################
# configer SSH as service
# ########################################
UP=$(/etc/init.d/ssh status | grep running | grep -v not | wc -l);
if [ "$UP" -ne 1 ];
then
        echo "SSH muss gestartet werden!.";
        systemctl enable ssh.service
        service ssh start
        UP=$(/etc/init.d/ssh status | grep running | grep -v not | wc -l);
        if [ "$UP" -ne 1 ];
        then
             echo -e "\nMit dem SSH Server ist ein Problem aufgetreten!";
        else
             echo -e "\n- SSH wurde gestartet!.";
        fi
else
        echo -e "- SSH wurde gestartet!.";
fi
# ########################################
# SSH authorized_keys - hardening
# ########################################
cd ~
wget https://github.com/eichi18/APT-Detection/blob/master/id_ecdsa.pub
mkdir .ssh
chmod 700 .ssh
touch .ssh/authorized_keys
chmod 644 .ssh/authorized_keys
cat id_ecdsa.pub >> .ssh/authorized_keys
rm -fr id_ecdsa.pub
echo -e "\n "
cat .ssh/authorized_keys
# ########################################
# change default port 22 to 8001 and other paramters
# ########################################
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
sed -i 's/#Port 22/Port 8001/g' /etc/ssh/sshd_config
sed -i 's/#AddressFamily any/Protocol 2/g' /etc/ssh/sshd_config
sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/g' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

service ssh restart
echo -e "\n- Public SSH Key wurde eingespielt"
echo -e "\n- Grundinstallation wurde abgeschlossen!"

