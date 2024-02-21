#!/bin/bash

FOLDER=$(echo $(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd) | awk -F/ '{print $NF}')

if [ -f ~/scripts/$FOLDER/config/env ]
 then
   echo "Config file found."  
 else
   read -p "Key name? "     KEY;       echo "KEY="$KEY               > ~/scripts/$FOLDER/config/env
   read -p "Moniker? "      MONIKER;   echo "MONIKER="$MONIKER      >> ~/scripts/$FOLDER/config/env
   read -p "Binary? "       BINARY;    echo "BINARY="$BINARY        >> ~/scripts/$FOLDER/config/env
   read -p "Network? "      NETWORK;   echo "NETWORK="$NETWORK      >> ~/scripts/$FOLDER/config/env
   read -p "Password? "     PWD;       echo "PWD="$PWD              >> ~/scripts/$FOLDER/config/env
   read -p "Min gas price?" GAS_PRICE; echo "GAS_PRICE="$GAS_PRICE  >> ~/scripts/$FOLDER/config/env
   read -p "Min gas adj? "  GAS_ADJ;   echo "GAS_ADJ="$GAS_ADJ      >> ~/scripts/$FOLDER/config/env
   read -p "Denom? "        DENOM;     echo "DENOM="$DENOM          >> ~/scripts/$FOLDER/config/env   
   echo "Config file created."
fi

source ~/scripts/$FOLDER/config/env

#install binary
#put instalation script here
$BINARY version

#init node and wallet
$BINARY init $MONIKER --chain-id=$NETWORK --home $HOME/.$BINARY
{ echo $PWD; sleep 1; echo $PWD } | $BINARY keys add $KEY

# genesis
read -p "Server to fetch genesis and seeds from? "  seed; 
curl -s $seed/$NETWORK/genesis > $HOME/.$BINARY/config/genesis.json

#seeds
sed -i 's|seeds =.*|seeds = "'$(curl -s $seed/$NETWORK/seeds)'"|g' $HOME/.$BINARY/config/config.toml

#min gas
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "$GAS_PRICE"/g' $HOME/.$BINARY/config/app.toml

#prunning
sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  $HOME/.$BINARY/config/app.toml

#change ports
read -p "Port set? " port_set;  
case $port_set in
 1) sed -i.bak -e "s%:26658%:27658%; s%:26657%:27657%; s%:6060%:6160%; s%:26656%:27656%; s%:26660%:27660%" $HOME/.$BINARY/config/config.toml 
    sed -i.bak -e "s%:9090%:9190%; s%:9091%:9191%; s%:1317%:1417%; s%:8545%:8645%; s%:8546%:8646%; s%:6065%:6165%" $HOME/.$BINARY/config/app.toml 
    sed -i.bak -e "s%:26657%:27657%" $HOME/.$BINARY/config/client.toml 
 ;;
 2) sed -i.bak -e "s%:26658%:28658%; s%:26657%:28657%; s%:6060%:6260%; s%:26656%:28656%; s%:26660%:28660%" $HOME/.$BINARY/config/config.toml
    sed -i.bak -e "s%:9090%:9290%; s%:9091%:9291%; s%:1317%:1517%; s%:8545%:8745%; s%:8546%:8746%; s%:6065%:6265%" $HOME/.$BINARY/config/app.toml
    sed -i.bak -e "s%:26657%:28657%" $HOME/.$BINARY/config/client.toml 
 ;;
 3) sed -i.bak -e "s%:26658%:29658%; s%:26657%:29657%; s%:6060%:6360%; s%:26656%:29656%; s%:26660%:29660%" $HOME/.$BINARY/config/config.toml
    sed -i.bak -e "s%:9090%:9390%; s%:9091%:9391%; s%:1317%:1617%; s%:8545%:8845%; s%:8546%:8846%; s%:6065%:6365%" $HOME/.$BINARY/config/app.toml 
    sed -i.bak -e "s%:26657%:29657%" $HOME/.$BINARY/config/client.toml 
 ;;
 4) sed -i.bak -e "s%:26658%:30658%; s%:26657%:30657%; s%:6060%:6460%; s%:26656%:30656%; s%:26660%:30660%" $HOME/.$BINARY/config/config.toml
    sed -i.bak -e "s%:9090%:9490%; s%:9091%:9491%; s%:1317%:1717%; s%:8545%:8945%; s%:8546%:8946%; s%:6065%:6465%" $HOME/.$BINARY/config/app.toml
    sed -i.bak -e "s%:26657%:30657%" $HOME/.$BINARY/config/client.toml 
 ;;
 5) sed -i.bak -e "s%:26658%:31658%; s%:26657%:31657%; s%:6060%:6560%; s%:26656%:31656%; s%:26660%:31660%" $HOME/.$BINARY/config/config.toml
    sed -i.bak -e "s%:9090%:9590%; s%:9091%:9591%; s%:1317%:1817%; s%:8545%:9045%; s%:8546%:9046%; s%:6065%:6565%" $HOME/.$BINARY/config/app.toml
    sed -i.bak -e "s%:26657%:31657%" $HOME/.$BINARY/config/client.toml 
 ;;
 *) ;; #default set
esac

#create service
sudo tee /etc/systemd/system/$BINARY.service > /dev/null << EOF
[Unit]
Description=$BINARY node service
After=network-online.target

[Service]
User=root
ExecStart=/usr/local/bin/$BINARY start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=/root/.$BINARY"
Environment="DAEMON_NAME=$BINARY"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable $BINARY.service

echo "Installation done, service is not started. Please run it with start.sh."
