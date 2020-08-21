#!/bin/bash

function pkg_install(){
        local vsw_path="https://www.openvswitch.org/releases/openvswitch-2.13.1.tar.gz"

        printf "[U] Instalando llaves del repositorio de docker..."
        $(sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - > /dev/null)
	printf "[OK]\n"

        printf "[U] Agregando el repositorio de docker..."
        $(sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /dev/null)
	printf "[OK]\n"

        printf "[U] Actualizando repositiorios..."
        $(sudo apt-get update -y > /dev/null)
	printf "[OK]\n"

        printf "[I] Instalando docker..."
        $(sudo apt-get install -y docker-ce > /dev/null)
	$(sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose)
	$(sudo chmod +x /usr/local/bin/docker-compose)
	printf "[OK]\n"

        printf "[I] Instalando compilador GCC..."
        $(sudo apt-get install -y gcc > /dev/null)
	printf "[OK]\n"

        printf "[I] Instalando Open vSwitch..."
        $(sudo apt-get install -y openvswitch-switch > /dev/null && sudo apt-get install -y openvswitch-common > /dev/null)
	printf "[OK]\n\n"
}

function config_switch(){
	printf "[!] Aprovisionando infraestructura: switch e interfaces virtuales\n"

	printf "[C] Configurando switch virtual [Nombre: copr_switch]... "
	$(sudo ovs-vsctl add-br corp_switch)
	printf "[OK]\n"

	printf "[C] Configurando interfaces en el switch..."

	for iface in $(seq 0 7);do
		printf "\t>> Agregando interface ether$iface... "
		if [ $iface -lt 2 ];then
			local vlan=10 #10.1.0.0/24
		elif [ $iface -le 3 ] && [ $iface -gt 1 ];then
			local vlan=20 #10.1.1.0/24
		elif [ $iface -le 5 ] && [ $iface -gt 3 ];then
			local vlan=30 #10.1.2.0/24
		elif [ $iface -le 7 ] && [ $iface -gt 5 ];then
			local vlan=40 #10.1.3.0/24
		fi

		$(sudo ip link add name vther$iface type veth peer name ether$iface)
		$(sudo ovs-vsctl add-port corp_switch ether$iface tag=$vlan)
		printf "[OK]\n"

	done
	printf "[OK] Switch listo!, configuracion:"
	printf ""

}

function container_deploy(){
        printf "[D] Agregando imagen docker de Kali linux..."
	$(sudo docker pull kalilinux/kali-rolling > /dev/null)
	local image_id=$(sudo docker images | grep -oP )
	printf "[OK]\n"
}


function veth_config(){
        echo ""
}

function main(){
        #pkg_install
	config_switch
}

main
