#!/bin/sh
### SENTORA SECURED - Domains - ss_domains.sh
##This script will create a list of all of the domains that a user owns to /var/sentora/secured/trueuserdomains.txt

#Empty/create the build files as well as back up the origianl trueuserdomains.txt
if [[ -f /var/sentora/secured/trueuserdomains.txt ]]
	then mv /var/sentora/secured/trueuserdomains.txt /var/sentora/secured/old/trueuserdomains.txt$(date +%m-%d-%Y_%H-%M-%S)
fi
> /tmp/users.id; > /tmp/users.name; > /var/sentora/secured/trueuserdomains.txt;

#Find all the user identification numbers
for i in `mysql -e 'use sentora_core; select ac_id_pk from x_accounts' |grep -v ac_id_pk`; 
	do echo "${i}" >> /tmp/users.id; done; 

#Find the usernames associated with those IDs.
for y in `cat /tmp/users.id`; 
    do for i in `mysql -e 'use sentora_core; select ac_user_vc from x_accounts where ac_id_pk="'"${y}"'"' |grep -v ac_user_vc`; 
		do echo "${y}:${i}:" >> /tmp/users.name; 
        done; 
done;

#Finally create the true user domains file
for x in `cat /tmp/users.name`;  
	do id=$(echo $x | cut -d: -f1);
	for z in `mysql -e 'use sentora_core; select vh_name_vc from x_vhosts where vh_acc_fk="'"$id"'" AND vh_deleted_ts IS NULL;' | grep -v vh_name_vc`
		do echo "${x}${z}" >> /var/sentora/secured/trueuserdomains.txt;
	done;
done;

#Cleanup
rm -rf /tmp/users.*; chown root: /var/sentora/secured/trueuserdomains.txt; chmod 660 /var/sentora/secured/trueuserdomains.txt

