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
echo -e "\n- Konfiguration wurde abgeschlossen!"
# change hostname
sed -i 's/raspberrypi/dionaea/g' /etc/hostname
sed -i 's/raspberrypi/dionaea/g' /etc/hosts
echo -e "\n- IP Adressen und Hostname wurden geändert"

# -------------------------------------------------------------
# Step 2) install dionaea
# -------------------------------------------------------------
# ########################################
#
# source: https://dionaea.readthedocs.io/en/latest/installation.html
# downloading source code of dionaea
cd ~
git clone https://github.com/DinoTools/dionaea.git
cd  dionaea
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
sudo make install
cp /opt/dionaea/etc/dionaea/dionaea.cfg /opt/dionaea/etc/dionaea/dionaea.cfg.dist
echo -e "\n- Dionaea wurde installiert"
# install ntp service
apt-get install ntp -y
# starting as service
cp /root/APT-Detection/dionaea/etc/init.d/dionaea /etc/init.d/
chmod 755 /etc/init.d/dionaea
update-rc.d dionaea defaults
/etc/init.d/dionaea start

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
cp ~/APT-Detection/dionaea/filebeat.yml /etc/filebeat/
echo -e "\n- Konfiguration für Filebeat Dionaea LogDateien wurde eingerichtet"
cat /etc/filebeat/filebeat.yml
systemctl enable filebeat.service
service filebeat start
sleep 3
service filebeat status

