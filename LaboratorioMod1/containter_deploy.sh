#!/bin/bash

swname="switch01"


function pkg_install(){
        vsw_path="https://www.openvswitch.org/releases/openvswitch-2.13.1.tar.gz"

        printf "[U] Instalando llaves del repositorio de docker..."
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - > /dev/null
	printf "[OK]\n"

        printf "[U] Agregando el repositorio de docker..."
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /dev/null
	printf "[OK]\n"

        printf "[U] Actualizando repositiorios..."
        sudo apt-get update -y > /dev/null
	printf "[OK]\n"

        printf "[I] Instalando docker..."
        sudo apt-get install -y docker-ce > /dev/null
	sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
	printf "[OK]\n"

        printf "[I] Instalando compilador GCC..."
        sudo apt-get install -y gcc > /dev/null
	printf "[OK]\n"

        printf "[I] Instalando Open vSwitch..."
        sudo apt-get install -y openvswitch-switch > /dev/null && sudo apt-get install -y openvswitch-common > /dev/null
	printf "[OK]\n\n"
}


function config_switch(){
	printf "[C] Configurando switch virtual [Nombre: switch01]... "
	sudo ovs-vsctl add-br $swname
	sudo ovs-vsctl set bridge $swname other_config:mac-aging-time=60
	sudo ovs-vsctl set bridge $swname other_config:mac-table-size=2048
	printf "[OK] Switch listo!\n"

}


function network_deploy(){
	printf "[D] Desplegango red virtual..."
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
	printf "[OK]\n"

	nmiface=$(sudo ovs-dpctl show | grep -P "port 6:.*" | cut -d ":" -f 2 | tr -d " ")

	printf "[C] configurando port-mirror en interface $nmiface... "
        sudo ovs-vsctl --id=@p get port $nmiface -- --id=@m create mirror name=m0 select-all=true output-port=@p -- set bridge $swname mirrors=@m
	printf "[OK]\n"

	printf "[T] Ajustando interface modo promiscuo en Nmonitor... "
        sudo docker exec nmonitor ip link set eth0 promisc on
        printf "[OK]\n"

        printf "[T] Desplegando Zeek... "
        sudo docker exec nmonitor zeekctl deploy > /dev/null
        printf "[OK]\n"

        printf "[T] Iniciando servicios en VLAN de servidores... "
        sudo docker exec -d server /bin/services.sh > /dev/null
	sleep 10
	sudo docker exec server service apache2 start > /dev/null
        printf "[OK]\n"
}


function container_deploy(){
	stcont=""
        printf "[D] Descargando script YAML para despliegue de contenedores..."
	$(wget -q --no-check-certificate https://raw.githubusercontent.com/jramirezgo/ITMDIR/master/LaboratorioMod1/docker-compose.yaml)
	printf "[OK]\n"
	printf "[I] Desplegando contenedores... "
	$(sudo docker-compose up -d)
	printf "[OK] Listo!\n"
}



function main(){
        #pkg_install
	config_switch
	container_deploy
	network_deploy
}

main
