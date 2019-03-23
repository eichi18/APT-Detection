# APT-Detection
## Installing a cowrie SSH honeypot for the APT-Detection System

1. Step - Base Installation
```bash
cd ~
git clone https://github.com/eichi18/APT-Detection.git
cd APT-Detection
chmod +x *.sh
./base_config.sh
```

2. Step - Cowrie SSH Honeypot Installation
```bash
cd ~/APT-Detection
./cowrie_config.sh
```

3. Step - Reboot the Raspberry Pi
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
    pip install --upgrade -r requirements.txt
    # start cowrie manually for test
    bin/cowrie start
```

After rebooting the raspberry pi cowrie will start automatically!

For more information please visit this link: https://cowrie.readthedocs.io/en/latest/INSTALL.html
