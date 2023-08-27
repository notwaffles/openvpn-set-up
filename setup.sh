#!/bin/bash

# Update and upgrade system
sudo apt update
sudo apt upgrade -y

# Install OpenVPN and EasyRSA
sudo apt install openvpn easy-rsa ufw -y

# Generate EasyRSA Certificates
make-cadir ~/openvpn-ca
cd ~/openvpn-ca

# Create Certificate Authority (CA)
source vars
./clean-all
./build-ca

# Generate Server Certificates
./build-key-server server

# Generate Diffie-Hellman Key
./build-dh

# Copy Certificates and Keys
sudo cp ~/openvpn-ca/keys/{server.crt,server.key,ca.crt,dh.pem} /etc/openvpn

# Create Server Configuration
sudo tee /etc/openvpn/server.conf > /dev/null << EOL
# OpenVPN server configuration
server 10.8.0.0 255.255.255.0
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 208.67.222.222"
push "dhcp-option DNS 208.67.220.220"
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn-status.log
verb 3
EOL

# Enable IP Forwarding
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Enable UFW and Configure Rules
sudo ufw allow OpenSSH
sudo ufw allow 1194/udp
sudo ufw enable

# Start and enable OpenVPN service
sudo systemctl start openvpn@server
sudo systemctl enable openvpn@server

echo "OpenVPN setup completed."
