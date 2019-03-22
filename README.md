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

for the finale step you must install cowrie with this commands:

```bash
    cd cowrie
    virutalenv cowrie-env
    source cowrie-env/bin/activate
    /home/cowrie/install.sh
```

