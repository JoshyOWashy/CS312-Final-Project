#!/bin/bash
yum update -y
yum install -y java-17-amazon-corretto

cd /home/ec2-user
mkdir minecraft
cd ./minecraft
mkdir server
cd ./server
wget https://piston-data.mojang.com/v1/objects/8f3112a1049751cc472ec13e397eade5336ca7ae/server.jar

echo "eula=true" >/home/ec2-user/minecraft/server/eula.txt

cat >/etc/systemd/system/minecraft.service <<EOF
[Unit]
Description=Minecraft Server
After=network.target

[Service]
Type=simple
ExecStart=sudo java -Xmx1024M -Xms1024M -jar server.jar nogui
WorkingDirectory=/home/ec2-user/minecraft/server
TimeoutStartSec=0

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload
systemctl enable minecraft.service
systemctl start minecraft.service
