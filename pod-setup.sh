#!/bin/bash
# Exit on any error
set -e
# Logging
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/root/logs/pod-setup.log 2>&1

# Arguments
infinit_user="$1"
odoh_capacity="$2"
infinit_bin="/opt/infinit/bin/infinit"
infinit_network="rep3.odoh.io"
infinit_captain="io.odoh.grid.captain"
# Check for variables
[[ -z "$infinit_user" ]] && { echo "ODOH grid user missing."; exit 1; }
[[ -z "$odoh_capacity" ]] && { echo "ODOH storage node capacity missing."; exit 1; }

# Zerotier
echo "============================================"
echo "ODOH: Start Zerotier"	
/usr/sbin/zerotier-one -d 
echo "###"
echo

echo "============================================"
echo "ODOH: Join Our Data Our Hands network"
/usr/sbin/zerotier-cli join e5cd7a9e1c178b15
echo "###"
echo

echo "============================================"
echo "ODOH: Wait for 10 seconds"
for i in {1..10}
do
  echo -n "."
  sleep 1s
done
echo
echo "###"
echo

# User
echo "============================================"
echo "ODOH: Check for $infinit_user"
user_exists="$($infinit_bin user list | grep $infinit_user)"
if [[ -z "$user_exists" ]]; then
	echo "Import $infinit_user"
	$infinit_bin user import --input /root/griduser
else
	echo "Found $infinit_user"
fi
echo "###"
echo

# O Captain! My Captain!
echo "============================================"
echo "ODOH: Check for $infinit_captain"
captain_exists="$($infinit_bin user list | grep $infinit_captain)"
if [[ -z "$captain_exists" ]]; then
	echo "Fetch $infinit_captain"
	$infinit_bin user fetch --as $infinit_user --name $infinit_captain
else
	echo "Found $infinit_captain"
fi
echo "###"
echo

# Network
echo "============================================"
echo "ODOH: Fetch networks"
/opt/infinit/bin/infinit network fetch --as $infinit_user
echo "###"
echo

# Volume
echo "============================================"
echo "ODOH: Fetch volumes"
/opt/infinit/bin/infinit volume fetch --as $infinit_user
echo "###"
echo

# Passport
echo "============================================"
echo "ODOH: Fetch passports"
/opt/infinit/bin/infinit passport fetch --as $infinit_user
echo "###"
echo

# Storage silo
echo "============================================"
echo "ODOH: Check for storage silo"
silo_exists="$($infinit_bin silo list | grep local)"
if [[ -z "$silo_exists" ]]; then
	echo "Create $odoh_capacity silo"
	$infinit_bin silo create --filesystem --capacity $odoh_capacity --as $infinit_user --name local
else
	echo "Found silo $silo_exists"
fi
echo "###"
echo

# Link network
echo "============================================"
echo "ODOH: Check for linked network"
network_linked="$($infinit_bin network list --as $infinit_user | grep $infinit_network | grep -v 'not linked')"
if [[ -z "$network_linked" ]]; then
	echo "Link $infinit_network network"
	$infinit_bin network link --as $infinit_user --name $infinit_captain/$infinit_network --storage local
else
	echo "Found network $network_linked"
fi
echo "###"
echo

# Attach storage
echo "============================================"
echo "ODOH: Attach storage to the grid"
$infinit_bin network run --as $infinit_user --name $infinit_captain/$infinit_network --async --cache --publish
echo "###"
echo