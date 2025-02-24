firewall {
    all-ping enable
    broadcast-ping disable
    config-trap disable
    ipv6-receive-redirects disable
    ipv6-src-route disable
    ip-src-route disable
    log-martians enable
    name politica_icmp {
        default-action drop
        rule 1 {
            action drop
            destination {
                address 10.2.0.0/24
            }
            protocol icmp
            source {
                address 10.1.0.0/24
            }
        }
    }
    name politica_servicios {
        default-action drop
        rule 1 {
            action accept
            destination {
                address 10.2.0.0/24
            }
            protocol icmp
            source {
                address 10.1.0.3/32
            }
        }
        rule 2 {
            action accept
            destination {
                address 10.2.0.0/24
                port 22,21,80,445
            }
            protocol tcp
            source {
                address 10.1.0.3/32
            }
        }
    }
    receive-redirects disable
    send-redirects enable
    source-validation disable
    syn-cookies enable
    twa-hazards-protection disable
}
interfaces {
    ethernet eth0 {
        address 172.16.0.2/24
    }
    ethernet eth1 {
        firewall {
            in {
            }
        }
        vif 10 {
            address 10.1.0.1/24
            firewall {
                in {
                    name politica_servicios
                }
            }
        }
        vif 20 {
            address 10.2.0.1/24
        }
    }
    loopback lo {
    }
}
nat {
    source {
        rule 10 {
            outbound-interface eth0
            translation {
                address masquerade
            }
        }
    }
}
protocols {
    static {
        route 0.0.0.0/0 {
            next-hop 172.16.0.1 {
                next-hop-interface eth0
            }
        }
    }
}
system {
    config-management {
        commit-revisions 100
    }
    host-name vyos
    login {
        user vyos {
            authentication {
                encrypted-password $6$QxPS.uk6mfo$9QBSo8u1FkH16gMyAVhus6fU3LOzvLR9Z9.82m3tiHFAxTtIkhaZSWssSgzt4v4dGAL8rhVQxTg0oAG9/q11h/
                plaintext-password ""
            }
        }
    }
    ntp {
        server 0.pool.ntp.org {
        }
        server 1.pool.ntp.org {
        }
        server 2.pool.ntp.org {
        }
    }
    syslog {
        global {
            facility all {
                level info
            }
            facility protocols {
                level debug
            }
        }
    }
}


/* Warning: Do not remove the following line. */
/* === vyatta-config-version: "broadcast-relay@1:cluster@1:config-management@1:conntrack@1:conntrack-sync@1:dhcp-relay@2:dhcp-server@5:dns-forwarding@2:firewall@5:https@1:interfaces@6:ipsec@5:l2tp@2:lldp@1:mdns@1:nat@4:ntp@1:pptp@1:qos@1:quagga@5:snmp@1:ssh@1:sstp@2:system@16:vrrp@2:vyos-accel-ppp@2:wanloadbalance@3:webgui@1:webproxy@2:zone-policy@1" === */
/* Release version: 1.3-rolling-202004010117 */
