#!/bin/bash

if [[ $UID -ne 0 ]];then
        printf "ERROR: Execute script with super powers!\n"
        exit 1
fi

printf "\n [*] Creating vswitch... "
ovs-vsctl add-br switch_lab3

printf "\n [*] Adding kali port to VLAN 10... "
ovs-docker add-port switch_lab3 eth0 kali --ipaddress="10.10.0.2/24" --gateway="10.10.0.1" && printf "PORT [OK]|"
ovs-docker set-vlan switch_lab3 eth0 kali 10 && printf "VLAN [OK]"

printf "\n [*] Adding workstation port to VLAN 10... "
ovs-docker add-port switch_lab3 eth0 workstation --ipaddress="10.10.0.3/24" --gateway="10.10.0.1" && printf "PORT [OK]|"
ovs-docker set-vlan switch_lab3 eth0 workstation 10 && printf "VLAN [OK]"

printf "\n [*] Adding firewall inside port as trunk interface... "
ovs-docker add-port switch_lab3 eth1 firewall && printf "PORT TRUNK [OK]"

printf "\n [*] Adding services subnet to VLAN 20... "
ovs-docker add-port switch_lab3 eth0 services --ipaddress="172.24.0.10/24" --gateway="172.24.0.1" && printf "PORT [OK]|"
ovs-docker set-vlan switch_lab3 eth0 services 20 && printf "VLAN [OK]\n"
