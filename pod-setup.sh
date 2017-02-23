#!/bin/bash
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
if [[ -z "$infinit_user" ]]; then
	echo "ODOH grid user missing."
	exit 1
fi

if [[ -z "$odoh_capacity" ]]; then
	echo "ODOH storage node capacity missing."
	exit 1
fi

# Zerotier
echo "============================================"
echo "ODOH: Start Zerotier"	
/usr/sbin/zerotier-one -d 
echo "###"
echo

echo "============================================"
echo "ODOH: Wait for ID generation"	
while [ ! -f /var/lib/zerotier-one/identity.secret ]; do
	echo -n "."
	sleep 1
done
echo 
echo "Success! Your ZeroTier address is [ `cat /var/lib/zerotier-one/identity.public | cut -d : -f 1` ]."
echo
echo
echo " *** PLEASE NOTE: The first time you connect to the Our Data Our Hands Zerotier"
echo " ***              network you will need to get authorization for your address."
echo 
echo
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
user_exists="$($infinit_bin user list | grep $infinit_user |grep private)"
if [[ -z "$user_exists" ]]; then
	# No user with private keys found here. Check for backup.
	echo "User not found, check for backup"
	if [[ ! -f "/root/.ssh/griduser" ]]; then
		echo "No backup found, create $infinit_user"
		echo '' | $infinit_bin user create --name $infinit_user --key /root/.ssh/id_rsa --push
		echo "Backup user"
		$infinit_bin user export --full --name $infinit_user --output /root/.ssh/griduser
		echo
		echo
		echo " *** PLEASE NOTE: You'll need approved passport permissions to start contributing"
		echo "                  your storage to humanity on the Our Data Our Hands network."
		echo
		echo

	else
		echo "Backup found, restore"
		$infinit_bin user import --input /root/.ssh/griduser
	fi
else
	echo "Found $infinit_user :)"
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
	link="$($infinit_bin network link --as $infinit_user --name $infinit_captain/$infinit_network --storage local)"
	echo $link
	if [[ $link == *"fatal error"* ]]; then
	  exit 1;
	fi	
else
	echo "Found network $network_linked"
fi
echo "###"
echo

# Attach storage
echo "============================================"
echo "ODOH: Attach storage to the grid"
storage_attached="$($infinit_bin network run --as $infinit_user --name $infinit_captain/$infinit_network --async --cache --publish)"
if [[ $storage_attached == *"fatal error"* ]]; then
  echo "Error attaching storage silo"
  echo $storage_attached
  exit 1;
fi
echo $storage_attached
echo "###"
echo