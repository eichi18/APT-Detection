# APT-Detection
## Base Installation for all Raspberry Pi

The base installation is for all honeypots the same. This is the basic installation of the Raspberry Pi.
```bash
sudo su
apt-get update
apt-get install git -y
cd ~
git clone https://github.com/eichi18/APT-Detection.git
cd APT-Detection
chmod +x *.sh
./base_config.sh
```
## Installing a cowrie SSH honeypot for the APT-Detection System
1. Step - Cowrie SSH Honeypot Installation
```bash
cd ~/APT-Detection
./cowrie_config.sh
```

2. Step - Reboot the Raspberry Pi
```bash
reboot
```

After the reboot yous must connect to Cowrie with the IP Adresse 10.0.0.20 and you have to use the private SSH Key and as user root!

Last Step - Finale Installation

for the finale step you must install cowrie once with this commands:

```bash
    su - cowrie
    cd cowrie
    virtualenv --python=python3 cowrie-env
    source cowrie-env/bin/activate
    pip install --upgrade pip
    pip install pycrypto Crypto
    pip install --upgrade -r requirements.txt
    # generate a key for the cowrie instance
    ssh-keygen -t dsa -b 1024 -f ./var/lib/cowrie/ssh_host_dsa_key
    ssh-keygen -t rsa -b 1024 -f ./var/lib/cowrie/ssh_host_dsa_key
    # start cowrie manually for test
    bin/cowrie start
```

After rebooting the raspberry pi all services will start automatically! The Cowrie SSH Honeypot is now ready for fine tuning.

For more information please visit this link: https://cowrie.readthedocs.io/en/latest/INSTALL.html

## Installing a dionaea Honeypot for the APT-Detection System

1. Step Dionaea Honeypot Installation
```bash
cd ~/APT-Detection
./dionaea_config.sh
``` 

## Installing a honeyd Honeypot for the APT-Detection System

1. Step Honeyd Honeypot Installation
```bash
cd ~/APT-Detection
./honeyd_config.sh
```

For more information please visit this link: http://www.honeyd.org/

## Installing a Glastopf Web-Application Honeypot for the APT-Detection System
1. Step Glastopf Honeypot Installation
```bash
cd ~/APT-Detection
./glastopf_config.sh
```
