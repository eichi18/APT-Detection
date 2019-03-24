
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
raspi_ip="10.0.0.20" # this ist the first honeypot
raspi_pubip="192.168.1.20"
raspi_net_mask="24"
raspi_pubnet_mask="24"
raspi_gateway="10.0.0.1"
raspi_pubgateway="192.168.1.1"
raspi_dns='208.67.222.222 208.67.220.220'
echo "###############################################"
echo "Installations-Script         Version 2019-01-18"
echo "Copyright Michael Eichinger                2019"
echo "###############################################"
echo "Cowrie Honeypot wird eingerichtet:"
echo "   Der Vorgang kann mehrere Minuten dauern, bitte um Geduld!"
echo " "
# ########################################
# edit SSH Banner
rm /etc/ssh/ssh-banner-cowrie.txt
cp ~/APT-Detection/ssh-banner-cowrie.txt /etc/ssh/
echo " - SSH Banner wurde erstellt"
cat /etc/ssh/ssh-banner-cowrie.txt
sed -i 's/#Banner none/Banner \/etc\/ssh\/ssh-banner-cowrie.txt/g' /etc/ssh/sshd_config
sed -i 's/ListenAddress 0.0.0.0/ListenAddress '$raspi_ip'/g' /etc/ssh/sshd_config
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
echo -e "\n- fixe" $raspi_ip " Management IP Adresse wurde eingerichtet"
echo -e "\n- fixe" $raspi_pubip " LAN IP Adresse wurde eingerichtet"
echo -e "\n- IP Adressen wurden geändert"
# change hostname
sed -i 's/raspberrypi/cowrie/g' /etc/hostname
sed -i 's/raspberrypi/cowrie/g' /etc/hosts
# -------------------------------------------------------------
# Step 2) install cowrie 
# -------------------------------------------------------------
# ########################################
#  install cowrie ssh honeypot
apt-get update
apt-get install python-virtualenv libssl-dev libffi-dev build-essential libpython3-dev python3-minimal authbind -y
# create an user account for cowrie
sudo adduser --disabled-password --gecos "" cowrie
echo -e "\n- warte 5 Sekunden"
sleep 5
cd /home/cowrie/
git clone http://github.com/cowrie/cowrie
chown cowrie:cowrie -R /home/cowrie/cowrie/
echo "[program:cowrie]" >> /etc/supervisor/conf.d/cowrie.conf
echo "command=/home/cowrie/cowrie/bin/cowrie start" >> /etc/supervisor/conf.d/cowrie.conf
echo "environment=PATH=\"/home/cowrie/cowrie/cowrie-env/bin:%(ENV_PATH)s\"" >> /etc/supervisor/conf.d/cowrie.conf
echo "user=cowrie" >> /etc/supervisor/conf.d/cowrie.conf
echo "autostart=true" >> /etc/supervisor/conf.d/cowrie.conf
echo "autorestart=true" >> /etc/supervisor/conf.d/cowrie.conf
echo "stopasgroup=true" >> /etc/supervisor/conf.d/cowrie.conf
echo "killasgroup=true" >> /etc/supervisor/conf.d/cowrie.conf
echo "stdout_logfile=/var/log/cowrie/cowrie.out.log" >> /etc/supervisor/conf.d/cowrie.conf
echo "stderr_logfile=/var/log/cowrie/cowrie.err.log" >> /etc/supervisor/conf.d/cowrie.conf
echo -e "\n- cowrie.conf für Supervisor wurde angelegt"
cat /etc/supervisor/conf.d/cowrie.conf
# create folder for cowrie log-file
mkdir /var/log/cowrie
cp /root/APT-Detection/cowrie/cowrie.cfg /home/cowrie/cowrie/etc/
# user defined cowrie.cfg.dist - we don't need kafka
rm /home/cowrie/cowrie/etc/cowrie.cfg.dist
cp ~/APT-Detection/cowrie/cowrie.cfg.dist /home/cowrie/cowrie/etc/
cp ~/APT-Detection/cowrie/cowrie /home/cowrie/cowrie/bin/
chown cowrie:cowrie /var/log/cowrie/
# -------------------------------------------------------------
# Step 3) install Filebeat for Raspberry Pi
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
# -------------------------------------------------------------
# Step 4) install Authbind
# -------------------------------------------------------------
sed -i 's/# DO NOT EDIT THIS FILE!/#/g' /home/cowrie/cowrie/etc/cowrie.cfg
sed -i 's/listen_endpoints = tcp:2222:interface=0.0.0.0/listen_endpoints = tcp:22:interface='$raspi_ip'/g' /home/cowrie/cowrie/etc/cowrie.cfg
sed -i 's/enabled = false/enabled = true/g' /home/cowrie/cowrie/etc/cowrie.cfg
sed -i 's/listen_endpoints = tcp:2223:interface=0.0.0.0/listen_endpoints = tcp:23:interface='$raspi_ip'/g' /home/cowrie/cowrie/etc/cowrie.cfg
touch /etc/authbind/byport/22
chown cowrie:cowrie /etc/authbind/byport/22
chmod 770 /etc/authbind/byport/22
touch /etc/authbind/byport/23
chown cowrie:cowrie /etc/authbind/byport/23
chmod 770 /etc/authbind/byport/23

# automatically start of filebeat
echo "[Unit]" >> /lib/systemd/system/filebeat.service
echo "Description=filebeat" >> /lib/systemd/system/filebeat.service
echo "Documentation=https://www.elastic.co/guide/en/beats/filebeat/current/index.html" >> /lib/systemd/system/filebeat.service
echo "Wants=userwork-online.target" >> /lib/systemd/system/filebeat.service
echo "After=network-online.target" >> /lib/systemd/system/filebeat.service
echo "[Service]" >> /lib/systemd/system/filebeat.service
echo "ExecStart=/usr/share/filebeat/bin/filebeat -c /etc/filebeat/filebeat.yml -path.home /usr/share/filebeat -path.config /etc/filebeat -path.data /var/lib/filebeat -path.logs /var/log/filebeat" >> /lib/systemd/system/filebeat.service
echo "Restart=always" >> /lib/systemd/system/filebeat.service
echo "[Install]" >> /lib/systemd/system/filebeat.service
echo "WantedBy=multi-user.target" >> /lib/systemd/system/filebeat.service
echo -e "\n- Konfiguration für Filebeat wurde erstellt"
cat /lib/systemd/system/filebeat.service
cp ~/APT-Detection/cowrie/filebeat.yml /etc/filebeat/
echo -e "\n- Konfiguration für Filebeat Cowrie LogDateien wurde eingerichtet"
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
echo -e "\n- COWRIE SSH Honeypot Konfiguration wurde abgeschlossen!"
echo -e "\n"
echo -e "\n zur finalen Endinstallation sind folgende Befehle erforderlich:"
echo -e "\n"
echo -e "\n    cd cowrie"
echo -e "\n    virutalenv --python=python3 cowrie-env"
echo -e "\n    source cowrie-env/bin/activate"
echo -e "\n    pip install --upgrade pip"
echo -e "\n    pip install --upgrade -r requirements.txt"
echo -e "\n"
echo -e "\n danach kann Cowrie gestartet werden "
echo -e "\n"
echo -e "\n   bin/cowrie start"

