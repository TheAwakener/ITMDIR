#!/bin/bash

if [[ $UID -ne 0 ]];then
        printf "ERROR: Execute this script with super powers!\n"
        exit 1
fi

printf "[*] Creating sub-interface with VLAN_ID 10...\n"
docker exec --privileged firewall vconfig add eth1 10

printf "[*] Creating sub-interface with VLAN_ID 20...\n"
docker exec --privileged firewall vconfig add eth1 20

printf "[*] Adding subinterfaces addressing...\n"
docker exec --privileged firewall ifconfig eth1.10 10.10.0.1 netmask 255.255.255.0 up
docker exec --privileged firewall ifconfig eth1.20 172.24.0.1 netmask 255.255.255.0 up

printf "[*] Cleaning default NAT and access rules...\n"
docker exec --privileged firewall iptables -F

printf "[*] Creating rule NAT for internet access...\n"
docker exec --privileged firewall iptables -t nat -A POSTROUTING -s "0.0.0.0/0" -o eth0 -j MASQUERADE
docker exec --privileged firewall iptables -A FORWARD -s 10.10.0.2 -d 172.24.0.10 -j DROP
