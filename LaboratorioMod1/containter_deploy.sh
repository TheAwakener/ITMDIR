#!/bin/bash

swname="switch01"


function pkg_install(){
        
        printf "[INSTALL]: Instalando llaves del repositorio de docker...\n"
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - > /dev/null

        printf "[INSTALL]: Agregando el repositorio de docker...\n"
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /dev/null

        printf "[UPDATE]: Actualizando repositiorios...\n"
        sudo apt-get update -y > /dev/null

        printf "[INSTALL]: Instalando docker...\n"
        sudo apt-get install -y docker-ce > /dev/null
	sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose > /dev/null
	sudo chmod +x /usr/local/bin/docker-compose

        printf "[INSTALL]: Instalando compilador GCC...\n"
        sudo apt-get install -y gcc > /dev/null

        printf "[INSTALL]: Instalando Open vSwitch...\n"
        sudo apt-get install -y openvswitch-switch > /dev/null && sudo apt-get install -y openvswitch-common > /dev/null
}


function config_switch(){
	printf "[CONFIG]: Configurando switch virtual [Nombre: switch01]...\n"
	sudo ovs-vsctl add-br $swname
	sudo ovs-vsctl set bridge $swname other_config:mac-aging-time=60
	sudo ovs-vsctl set bridge $swname other_config:mac-table-size=2048
}


function network_deploy(){
	printf "[DEPLOY]: Desplegango red virtual...\n"
	cont_names=("kali" "workstation" "server" "gateway" "nmonitor")
	for container in ${cont_names[*]}; do
		contid=$(sudo docker ps -q -f name=$container)
		if [ $container == "kali" ];then
			sudo ovs-docker add-port $swname eth0 $contid --macaddress="f2:e3:0d:39:7f:d4"
			#--ipaddress=10.1.0.2/24 --gateway=10.1.0.1
			#sudo ovs-docker set-vlan $swname eth0 $contid 10
		elif [ $container == "workstation" ]; then
			sudo ovs-docker add-port $swname eth0 $contid --ipaddress=10.1.0.3/24 --gateway=10.1.0.1 --macaddress="c2:c3:ad:49:7a:39"
                        sudo ovs-docker set-vlan $swname eth0 $contid 10
		elif [ $container == "server" ];then
			sudo ovs-docker add-port $swname eth0 $contid --ipaddress=10.2.0.2/24 --gateway=10.2.0.1 --macaddress="a2:c3:0d:49:7e:ff"
			sudo ovs-docker set-vlan $swname eth0 $contid 20
		elif [ $container == "gateway" ]; then
			sudo ovs-docker add-port $swname eth1 $contid --macaddress="a2:c3:0d:49:7f:10"
		elif [ $container == "nmonitor"  ];then
			sudo ovs-docker add-port $swname eth0 $contid
		fi
	done

	nmiface=$(sudo ovs-dpctl show | grep -P "port 6:.*" | cut -d ":" -f 2 | tr -d " ")

	printf "\t[CONFIG] configurando port-mirror en interface $nmiface...\n"
        sudo ovs-vsctl --id=@p get port $nmiface -- --id=@m create mirror name=m0 select-all=true output-port=@p -- set bridge $swname mirrors=@m

	printf "\t[CONFIG]: Ajustando interface modo promiscuo en Nmonitor...\n"
        sudo docker exec nmonitor ip link set eth0 promisc on

        printf "\t[CONFIG]: Desplegando Zeek...\n"
        sudo docker exec nmonitor zeekctl deploy > /dev/null

        printf "\t[CONFIG]: Iniciando servicios en VLAN de servidores...\n"
        sudo docker exec -d server /bin/services.sh > /dev/null
	sleep 10
	sudo docker exec -d server service apache2 start > /dev/null

	printf "\t[CONFIG]: Ajustando IPTABLES...\n"
	sudo docker exec -d server iptables -A INPUT -s 10.1.0.0/24 -d 0.0.0.0/0 -j ACCEPT > /dev/null
	sudo docker exec -d server iptables -P INPUT DROP > /dev/null
	printf "[OK]\n"
	
	printf "[CONFIG] Configurando router/firewall...\n"
	sudo docker exec -d gateway su vyos sg vyattacfg -c scripts/provision.sh
}

function container_deploy(){
	stcont=""
        printf "[DEPLOY]: Descargando script YAML para despliegue de contenedores...\n"
	$(wget -q --no-check-certificate https://raw.githubusercontent.com/jramirezgo/ITMDIR/master/LaboratorioMod1/docker-compose.yaml)
	
	printf "[DEPLOY]: Desplegando contenedores...\n"
	$(sudo docker-compose up -d)
}



function main(){
        pkg_install
	config_switch
	container_deploy
	network_deploy
}
main
