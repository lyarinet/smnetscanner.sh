# Nmap Eth Selector

A powerful and simple Bash script for scanning devices on your local network using `nmap`. This script allows you to select a specific network interface or scan all interfaces, and displays detailed information like IP address, MAC address, hostname, domain/workgroup, and manufacturer.

## Features

- Interactive interface selection (`eth0`, `ens18`, etc.)
- Option to scan all active interfaces at once
- Uses `nmap` to scan the local subnet
- Extracts:
  - IP addresses
  - MAC addresses
  - Hostnames
  - Workgroup/Domain names
  - Manufacturer info
- Falls back to DHCP lease file for hostname if `nmap` cannot detect it

## Requirements

- `nmap`
- Run as `root` or with `sudo`

Install `nmap` on Debian/Ubuntu:
```bash
sudo apt update && sudo apt install nmap
```

## Usage

```bash
chmod +x on.sh
sudo ./on.sh
```

You will be prompted to choose an interface:
```
Available network interfaces:
ens18
ens19
docker0
Type 'all' to scan all interfaces
Enter the interface to scan (e.g., eth0, ens33, or all):
```

### Example Output
```
IP             | MAC              | HOSTNAME         | WG-DOMAIN      | MANUFACTURER                 
-------------  | ---------------- | ---------------- | ---------------| -----------------------------
10.0.0.2       | AA:BB:CC:DD:EE:FF | server1          | WORKGROUP      | Intel Corporate              
```

A `*` next to the hostname means it was retrieved from the DHCP lease file.

## Disclaimer

This script is provided "as is" without warranty. Use at your own risk.

---
Script provided free of charge by ServerMatter
