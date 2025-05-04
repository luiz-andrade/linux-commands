#!/bin/bash

# ✅ Ligar pela rede (Wake-on-LAN - WoL)
# O Wake-on-LAN permite que o computador seja ligado remotamente através de um pacote especial (Magic Packet).

# Etapas:
# Habilite o WoL na BIOS/UEFI
# Acesse o setup da BIOS ao ligar a máquina.
# Procure por Wake-on-LAN ou algo como “Power on by PCI-E” e ative.

## Descubra o MAC address da máquina: ip link show enp3s0 (anote)

## Torne o script executável: chmod +x wol-setup.sh
## Execute: ./wol-setup.sh
## Verifique se o WoL ficou ativo: ethtool <sua-interface>
## Deve mostrar: Wake-on: g
## No servidor: systemctl suspend

## Envie o pacote WoL de outro computador:
## Instale o wakeonlan: apt install wakeonlan
## E envie o pacote: wakeonlan 00:11:22:33:44:55
## Substitua pelo MAC da máquina desligada/hibernada.


# Nome da interface de rede
IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1)

# Verifica se a interface foi encontrada
if [ -z "$IFACE" ]; then
    echo "Interface de rede não encontrada!"
    exit 1
fi

echo "Interface detectada: $IFACE"

# Ativa WoL no modo 'g' (Magic Packet)
echo "Ativando Wake-on-LAN para $IFACE..."
sudo ethtool -s "$IFACE" wol g

# Cria serviço systemd para aplicar WoL no boot
echo "Criando serviço systemd para manter WoL ativo após boot..."

sudo tee /etc/systemd/system/wol.service > /dev/null <<EOF
[Unit]
Description=Wake-on-LAN para $IFACE
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/ethtool -s $IFACE wol g

[Install]
WantedBy=multi-user.target
EOF

# Ativa o serviço no boot
sudo systemctl daemon-reexec
sudo systemctl enable wol.service
sudo systemctl start wol.service

echo "Wake-on-LAN configurado e persistente para $IFACE!"
