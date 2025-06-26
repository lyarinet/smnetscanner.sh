#!/bin/bash
# (c) Lyarinet, Asifagaria
# no warranty expressed or implied - use as is.
# See https://www.youtube.com/watch?v=4hjskxkapYo

# versioned here: https://github.com/lyarinet/smnetscanner.sh.git
# history of the github:
# 2025-06-26 downloaded from https://github.com/lyarinet/smnetscanner.sh.git - Modified to selected eth?

# purpose of this script:
# Can't use angryipscanner from a command line and haven't been able to find anything else that gives you what you're looking for?   
# This nmap based bash script might just be what you're looking for. 

# Check for nmap installation
if ! which nmap >/dev/null; then
    echo "nmap is not installed - this script requires it"
    echo "It can be installed with - apt install nmap"
    exit 1
fi

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root user or with sudo"
    exit 1
fi

lease_file_location="/var/lib/dhcp/dhcpd.leases"

# Prompt the user to select a network interface or scan all
echo "Available network interfaces:"
ip -o link show | awk -F': ' '{print $2}' | grep -v "lo"
echo "Type 'all' to scan all interfaces"
read -p "Enter the interface to scan (e.g., eth0, ens33, or all): " selected_interface

interfaces=()
if [ "$selected_interface" == "all" ]; then
    mapfile -t interfaces < <(ip -o -f inet addr show | awk '!/ lo / {print $2}' | sort -u)
else
    if ! ip link show "$selected_interface" > /dev/null 2>&1; then
        echo "Invalid network interface: $selected_interface"
        exit 1
    fi
    interfaces=("$selected_interface")
fi

# Collect all IPs to scan
all_ips=()
for iface in "${interfaces[@]}"; do
    ip_and_cidr=$(ip -o -f inet addr show "$iface" | awk '{print $4}')

    if [ -z "$ip_and_cidr" ]; then
        echo "No IP address found on $iface, skipping."
        continue
    fi

    ip_range=$(echo "$ip_and_cidr" | sed 's/\.[0-9]*\//.0\//')

    echo -e "\nRunning nmap -sn $ip_range on interface $iface\n"
    mapfile -t iface_ips < <(nmap -sn "$ip_range" | awk '/Nmap scan report/{gsub(/[()]/,"",$NF); print $NF}')
    all_ips+=("${iface_ips[@]}")
done

# Remove duplicate IPs and sort
IFS=$'\n' read -r -d '' -a ips < <(printf "%s\n" "${all_ips[@]}" | sort -u && printf '\0')

# Set column widths
col1=14
col2=17
col3=17
col4=15
col5=30

echo -e "Checking each IP address for Hostname, MAC, Workgroup or Domain, Manufacturer info\n"

# Format header
printf "%-${col1}s | %-${col2}s | %-${col3}s | %-${col4}s | %-${col5}s \n" "IP" "MAC" "HOSTNAME" "WG-DOMAIN" "MANUFACTURER"
printf "%-${col1}s | %-${col2}s | %-${col3}s | %-${col4}s | %-${col5}s \n" \
  "$(printf '%.s-' {1..13})" "$(printf '%.s-' {1..17})" "$(printf '%.s-' {1..17})" "$(printf '%.s-' {1..15})" "$(printf '%.s-' {1..30})"

for IP in "${ips[@]}"
do
  OUTPUT="$(nmap --script nbstat.nse -p 137,139 "$IP")"
  MAC=$(echo "$OUTPUT" | grep 'MAC Address' | awk '{print $3}')
  HOSTNAME=$(echo "$OUTPUT" | grep '<20>.*<unique>.*<active>' | awk -F'[|<]' '{print $2}' | tr -d '_' | xargs)
  WG_DOMAIN=$(echo "$OUTPUT" | grep -v '<permanent>' | grep '<00>.*<group>.*<active>' | awk -F'[|<]' '{print $2}' | tr -d '_' | xargs)
  MANUFACTURER=$(echo "$OUTPUT" | grep 'MAC Address' | awk -F'(' '{print $2}' | cut -d ')' -f1)

  if [ -f "$lease_file_location" ]; then
    if [ -z "$HOSTNAME" ]; then
      HOSTNAME=$(awk -v ip="$IP" '$1 == "lease" && $2 == ip {f=1} f && /client-hostname/ {print substr($2, 2, length($2) - 3); exit}' "$lease_file_location" | cut -c 1-15)
      if [ -n "$HOSTNAME" ]; then
        HOSTNAME="$HOSTNAME *"
      fi
    fi
  fi

  printf "%-${col1}s | %-${col2}s | %-${col3}s | %-${col4}s | %-${col5}s \n" "$IP" "$MAC" "$HOSTNAME" "$WG_DOMAIN" "$MANUFACTURER"
done

if [ -f "$lease_file_location" ]; then
  echo -e "\n* to the right of hostname indicates the hostname could not be acquired from nmap so was pulled from $lease_file_location\n"
fi

echo -e "This network scanner script is provided free of charge by Asifagaria\n"
