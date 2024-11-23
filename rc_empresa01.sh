#!/usr/bin/env bash
# Firewall da empresa 1
# NAT - rede interna para a interface externa
# eth1 - interface externa (WAN)
# eth0 - interface interna (LAN)
# eth2 - interface DMZ
# Ativa o roteamento
echo 1 > /proc/sys/net/ipv4/ip_forward
#### Ativa Modulos
        /sbin/modprobe ip_conntrack
        /sbin/modprobe ip_conntrack_ftp
        /sbin/modprobe ip_nat_ftp
        /sbin/modprobe ipt_LOG
#### Limpa tabelas e configura defaults
        iptables -F -t filter
        iptables -F -t nat
        iptables -F -t mangle
        ## Delete chains nao defaults
        iptables -X
        iptables -X -t nat
        iptables -X -t mangle
        # Política DROP, chains INPUT e FORWARD
        iptables -P INPUT  DROP -t filter
        iptables -P OUTPUT ACCEPT -t filter
        iptables -P FORWARD DROP -t filter
                # para manter as conexoes existentes com o proprio firewall (entrada)
        iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
        # para manter as conexoes existentes com o proprio firewall (saida)
        iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
                # para manter as conexoes passando pelo firewall
        iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT


# Libera acesso ao ICMP (Ping) nas interfaces LAN, DMZ e WAN
iptables -A INPUT -i eth0 -p icmp -j ACCEPT
iptables -A INPUT -i eth1 -p icmp -j ACCEPT
iptables -A INPUT -i eth2 -p icmp -j ACCEPT
# Libera SSH na porta 22
iptables -A INPUT -i eth1 -p tcp  -s 0/0 --dport 22 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp  -s 0/0 --dport 22 -j ACCEPT
iptables -A INPUT -i eth2 -p tcp  -s 0/0 --dport 22 -j ACCEPT
# Libera a resolucao de DNS no servidor local  (LAN e DMZ)
iptables -A INPUT -i eth0 -p udp -s 192.168.0.0/24 -d 0/0 --dport 53 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i eth2 -p udp -s 200.10.5.0/24 -d 0/0 --dport 53 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
# Mantem o estado das conexoes da interface de loopback 
iptables -A INPUT  -s 127.0.0.1  -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT  -s 127.0.0.1  -m state --state RELATED,ESTABLISHED -j ACCEPT
# Libera todos os acesso originados de localhost para localhost
iptables -A INPUT -s 127.0.0.1 -d 127.0.0.1  -j ACCEPT
# Ativa mascaramento (rede interna para o IP da WAN) (IP Fixo)
iptables -t nat -A POSTROUTING -o eth1 -j SNAT -s 192.168.0.0/24 --to-source 200.10.4.2
"rc_empresa1.txt" 87L, 4358C                                                                                                                                                1,1           Top

