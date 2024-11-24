#!/usr/bin/env bash
# Firewall da empresa 2
# NAT - rede interna para a interface externa
# eth1 - interface externa (WAN)
WAN='200.16.5.1'
# eth0 - interface interna (LAN)
LAN='172.16.4.0/24'
# eth2 - interface DMZ
DMZ='200.16.6.0/24'
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
iptables -A INPUT -i eth0 -p udp -s $LAN -d 0/0 --dport 53 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i eth2 -p udp -s $DMZ -d 0/0 --dport 53 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
# Mantem o estado das conexoes da interface de loopback
iptables -A INPUT  -s 127.0.0.1  -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT  -s 127.0.0.1  -m state --state RELATED,ESTABLISHED -j ACCEPT
# Libera todos os acesso originados de localhost para localhost
iptables -A INPUT  -s 127.0.0.1 -d 127.0.0.1  -j ACCEPT
# Ativa mascaramento (rede interna para o IP da WAN) (IP Fixo)
iptables -t nat -A POSTROUTING -o eth1 -j SNAT -s $LAN --to-source $WAN

### Liberacoes (rede interna (LAN) para fora)
# Servicos comuns
iptables -A FORWARD -i eth0 -p tcp -m multiport -s $LAN -d 0/0 --dports 22,80,443,5001 -j ACCEPT
# Host 192.168.0.12 bloqueado ICMP para fora
#iptables -A FORWARD -i eth0 -p icmp -s 192.168.0.12/32 -d 0/0 -j DROP
# ICMP
iptables -A FORWARD -i eth0 -p icmp -s $LAN -d 0/0 -j ACCEPT
# DNS, NTP
iptables -A FORWARD -i eth0 -p udp -s $LAN -d 0/0 -m multiport --dports 53,143 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
# Redireciona portas (porta publica: 5001, IP interno: 192.168.0.10, Porta interna: 5001)
#iptables -A FORWARD -i eth1 -d 192.168.0.10/32 -j ACCEPT

# Redirecionamento 172.16.4.10
iptables -A FORWARD -i eth1 -d 172.16.4.10/32 -j ACCEPT
iptables -A FORWARD -t nat -p tcp -s $WAN --port 4008 -j DNAT --to 172.16.4.10:4008
iptables -A FORWARD -t nat -p tcp -s $WAN --port 12345 -j DNAT --to 172.16.4.10:12345
iptables -A FORWARD -t nat -p tcp -s $WAN --port 5201 -j DNAT --to 172.16.4.10:5201




### Liberacoes (rede DMZ para fora)
# Servicos comuns
#iptables -A FORWARD -i eth2 -p tcp -m multiport -s 200.10.3.0/24 -d 0/0 --dports 22,80,443,5001 -j ACCEPT
# ICMP
#iptables -A FORWARD -i eth2 -p icmp -s 200.10.3.0/24 -d 0/0 -j ACCEPT
# DNS, NTP
#iptables -A FORWARD -i eth0 -p udp -s 200.10.3.0/24 -d 0/0 -m multiport --dports 53,143 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

## Liberacoes (rede externa para a DMZ)
# Liberacao de acesso na porta 3000
iptables -A FORWARD -p tcp -d 200.16.6.10 --dport 3000 -j ACCEPT


# Host externo 200.10.0.10, bloqueado o acesso a porta 22 no servidor 200.10.3.10
#iptables -A FORWARD -i eth1 -p tcp -s 200.10.0.10/32 -d 200.10.3.10/32 --dport 22 -j DROP
# Servicos comuns, somente para o servidor 200.10.3.10
#iptables -A FORWARD -i eth1 -p tcp -m multiport -s 0/0 -d 200.10.3.10/32 --dports 22,80,443,5001 -j ACCEPT
# SSH e HTTP, somente para o servidor 200.10.3.11
#iptables -A FORWARD -i eth1 -p tcp -m multiport -s 0/0 -d 200.10.3.11/32 --dports 22,80 -j ACCEPT
# ICMP
#iptables -A FORWARD -i eth1 -p icmp -s 200.10.3.0/24 -d 0/0 -j ACCEPT
# Host externo 200.10.0.10, acesso a porta 5001 no servidor 200.10.3.11
#iptables -A FORWARD -i eth1 -p tcp -s 200.10.0.10/32 -d 200.10.3.11/32 --dport 5001 -j ACCEPT

# Libera OSPF
iptables -A INPUT -p ospf -j ACCEPT
iptables -A OUTPUT -p ospf -j ACCEPT