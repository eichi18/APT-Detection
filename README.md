# APT-Detection
## Installing a cowrie SSH honeypot for the APT-Detection System

1. Step - Base Installation
```bash
cd ~
wget https://raw.githubusercontent.com/eichi18/APT-Detection/master/base_config.sh
chmod +x base_config.sh
./base_config.sh
```

2. Step - Cowrie SSH Honeypot Installation
```bash
cd ~
wget https://raw.githubusercontent.com/eichi18/APT-Detection/master/cowrie_config.sh
chmod +x cowrie_config.sh
./cowrie_config.sh
```

3. Step - Reboot the Raspberry Pi
```bash
reboot
```

After the reboot yous must connect to Cowrie with the IP Adresse 10.0.0.20 and you have to use the private SSH Key and as user root!

Last Step - Finale Installation

for the finale step you must install cowrie with this commands:

```bash
    su - cowrie
    cd cowrie
    virtualenv cowrie-env
    source cowrie-env/bin/activate
    # start cowrie manually for test
    bin/cowrie start
```

After rebooting the raspberry pi cowrie will start automatically!
