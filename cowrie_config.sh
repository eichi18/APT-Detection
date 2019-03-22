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
cd /etc/ssh/
wget https://raw.githubusercontent.com/eichi18/APT-Detection/master/ssh-banner-cowrie.txt
echo " - SSH Banner wurde erstellt"
cat /etc/ssh/ssh-banner-cowrie.txt
sed -i 's/#Banner none/Banner \/etc\/ssh\/ssh-banner-cowrie.txt/g' /etc/ssh/sshd_config
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
echo -e "\n-fixe" $raspi_pubip " Management IP Adresse wurde eingerichtet"
echo -e "\n-fixe" $raspi_ip " LAN IP Adresse wurde eingerichtet"
echo -e "\n- Konfiguration wurde abgeschlossen!"
# -------------------------------------------------------------
# Step 2) install cowrie 
# -------------------------------------------------------------
# ########################################
#  install cowrie ssh honeypot
apt-get update
apt-get install git python-virtualenv libssl-dev libffi-dev build-essential libpython-dev python2.7-minimal authbind virtualenv -y
# create an user account for cowrie
sudo adduser --disabled-password --gecos "" cowrie
echo -e "\n- warte 5 Sekunden"
sleep 5
cd /home/cowrie/
git clone http://github.com/micheloosterhof/cowrie
chown cowrie:cowrie -R /home/cowrie/cowrie/
apt-get install -y python3-pip
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
# create folder for cowrie log-file
mkdir /var/log/cowrie
chown cowrie:cowrie /var/log/cowrie/
# upgrade pip
pip install --upgrade pip
pip install --upgrade -r requirements.txt
# -------------------------------------------------------------
# Step 3) install Filebeat for Raspberry Pi
# -------------------------------------------------------------
#
# install Go 1.10.3
cd ~
git clone https://github.com/tgogos/rpi_golang.git
cd rpi_golang/
tar -xzf go1.4.3.linux-armv7.tar.gz -C /usr/local/
export PATH=/usr/local/go/bin:$PATH
echo "export PATH=/usr/local/go/bin:$PATH" >> /root/.bashrc
echo -e "\n- Installation:" go version "abgeschlossen"
rm -fr $HOME/go1.4
tar -xzf go1.4.3.linux-armv7.tar.gz -C $HOME/go1.4 --strip-components=1
rm -fr /usr/local/go
wget https://dl.google.com/go/go1.10.3.src.tar.gz
tar -xz -C /usr/local -f go1.10.3.src.tar.gz
rm -fr /usr/local/go
wget https://dl.google.com/go/go1.10.3.src.tar.gz
tar -xz -C /usr/local -f go1.10.3.src.tar.gz
cd /usr/local/go/src
time GOROOT_BOOTSTRAP=/root/go1.4 ./make.bash
echo -e "\n- Installation:" go version "abgeschlossen"
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
# and for the `bee` tool:
export PATH=$PATH:$GOPATH/bin
#
# install Beats



# login as cowrie user to install the software
echo -e "\n- Konfiguration wurde abgeschlossen!"
echo -e "\n"
echo -e "\n zur finalen Endinstallation sind folgende Befehle erforderlich:"
echo -e "\n"
echo -e "\n    cd cowrie"
echo -e "\n    virutalenv cowrie-env"
echo -e "\n    source cowrie-env/bin/activate"
echo -e "\n"
echo -e "\n"
echo -e "\n danach kann Cowrie gestartet werden "
echo -e "\n"
echo -e "\n   bin/cowrie start"
