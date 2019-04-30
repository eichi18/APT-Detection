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
# Step 1) base configuration
# -------------------------------------------------------------
if [ $(id -u) -ne 0 ]; then
  printf "This script must be run as root. \n"
  exit 1
fi
# ########################################
# set parameter for this raspberry pi
raspi_ip="10.0.0.30"
raspi_net_mask="24"
raspi_gateway="10.0.0.1"
raspi_dns='208.67.222.222 208.67.220.220'
echo "###############################################"
echo "Installations-Script         Version 2019-03-26"
echo "Copyright Michael Eichinger                2019"
echo "###############################################"
echo "Raspberry Pi Grundkonfiguration wird eingerichtet:"
echo "   Der Vorgang kann mehrere Minuten dauern, bitte um Geduld!"
echo " "
echo -e "\n- Updates werden eingespielt"
apt-get update
apt-get upgrade -y
# ########################################
# set up time zone
echo "Europe/Vienna" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata > /dev/null 2> /dev/null
date +%Z | egrep -q "^CE(S){0,1}T$" > /dev/null 2> /dev/null && echo "- Zeitzone wurde eingerichtet." || echo "FEHLER: Zeitzone konnte nicht eingerichtet werden!"
# ########################################
# current system time
# https://wiki.archlinux.org/index.php/Systemd-timesyncd
echo "------------------------------------------------"
echo "        aktuelle Zeit:"
echo "------------------------------------------------"
timedatectl status
echo "------------------------------------------------"
#
# ########################################
# set language
#sed -i 's/en_GB.UTF-8 UTF-8/# en_GB.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/# de_AT.UTF-8 UTF-8/de_AT.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen > /dev/null 2> /dev/null
update-locale LANG=de_AT.UTF-8 LANGUAGE=de_AT:de > /dev/null 2> /dev/null && echo "- Sprache wurde eingerichtet." || echo "FEHLER: Sprache konnte nicht eingerichtet werden!"
# ########################################
# set up keyboard layout
sed -i 's/XKBLAYOUT=gb/XKBLAYOUT=at/g' /etc/default/keyboard
dpkg-reconfigure --frontend=noninteractive keyboard-configuration > /dev/null 2> /dev/null
invoke-rc.d keyboard-setup start > /dev/null 2> /dev/null
debconf-get-selections | grep "xkb-keymap" | grep "at" > /dev/null 2> /dev/null && echo "- Tastaturlayout wurde eingerichtet." || echo "FEHLER: Tastaturlayout konnte nicht eingerichtet wer108.67.222.222 208.67.220.220 ' /etc/dhcpcd.conf
den!"
# ########################################
# setup ip address
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
cp ./APT-Detection/id_ecdsa.pub ~
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
# -------------------------------------------------------------
# Step 4) install Filebeat for Raspberry Pi
# -------------------------------------------------------------
cd ~/APT-Detection/
mkdir /etc/filebeat
file="/root/APT-Detection/filebeat/filebeat-6.4.0-linux-x86.tar.gz"
if [ -f "$file" ];
then
    # File exist!
    tar -xf ~/APT-Detection/filebeat/filebeat-6.4.0-linux-x86.tar.gz -C /etc/filebeat
    echo -e "\n- Filebeat wurde enpackt und nach /etc/filebeat kopiert"
else
    # File doese not exist
    cd ~
    git clone https://github.com/eichi18/APT-Detection.git
    tar -xf ~/APT-Detection/filebeat/filebeat-6.4.0-linux-x86.tar.gz -C /etc/filebeat
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
# automatically start of filebeat
echo "[Unit]" >> /lib/systemd/system/filebeat.service
echo "Description=filebeat" >> /lib/systemd/system/filebeat.service
echo "Documentation=https://www.elastic.co/guide/en/beats/filebeat/current/inde$
echo "Wants=userwork-online.target" >> /lib/systemd/system/filebeat.service
echo "After=network-online.target" >> /lib/systemd/system/filebeat.service
echo "[Service]" >> /lib/systemd/system/filebeat.service
echo "ExecStart=/usr/share/filebeat/bin/filebeat -c /etc/filebeat/filebeat.yml $
echo "Restart=always" >> /lib/systemd/system/filebeat.service
echo "[Install]" >> /lib/systemd/system/filebeat.service
echo "WantedBy=multi-user.target" >> /lib/systemd/system/filebeat.service
echo -e "\n- Konfiguration fuer Filebeat wurde erstellt"
cat /lib/systemd/system/filebeat.service
# -------------------------------------------------------------
# Step 5) Supervisor installation
# -------------------------------------------------------------
apt-get install supervisor -y
/etc/init.d/supervisor enable
/etc/init.d/supervisor start
echo -e "\n- Supervisor wurde installiert"
# #########################################
# add SSH Server monitoring to supervisor
touch /etc/supervisor/conf.d/ssh.conf
echo "[program:ssh]" >> /etc/supervisor/conf.d/ssh.conf
echo "command=/etc/init.d/ssh start" >> /etc/supervisor/conf.d/ssh.conf
echo "user=root" >> /etc/supervisor/conf.d/ssh.conf
echo "autostart=true" >> /etc/supervisor/conf.d/ssh.conf
echo "autorestart=true" >> /etc/supervisor/conf.d/ssh.conf
echo "stopasgroup=true" >> /etc/supervisor/conf.d/ssh.conf
echo "killasgroup=true" >> /etc/supervisor/conf.d/ssh.conf
echo "stdout_logfile=/var/log/ssh.out.log" >> /etc/supervisor/conf.d/ssh.conf
echo "stderr_logfile=/var/log/ssh.err.log" >> /etc/supervisor/conf.d/ssh.conf
echo -e "\n- SSH Server Ueberwachung wurde zu Supervisor hinzugefuegt"
echo -e "\n- Grundinstallation wurde abgeschlossen!"
echo "-------------------------------------------------------"
echo "  Fortsetzen mit eigentlicher Honeypot Installation    "
echo "-------------------------------------------------------"
