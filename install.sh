#!/bin/sh
###SENTORA SECURED - Installer
##v0.3-3

#Set up Sentora Secured's installation directory
mkdir /var/sentora/secured/ /var/sentora/secured/uninstall/ /var/sentora/secured/old 2&>1 /dev/null
chown root.root /var/sentora; chmod 770 /var/sentora/

#Disable Pro-FTPD. SSH will be handling SFTP.
echo "ProFTPD is being disabled. Only SFTP protocols will be allowed for file transfer."
service proftpd stop; chkconfig proftpd off 2&>1 /dev/null; systemctl disable proftpd 2&>1 /dev/null;

#Backup the original Sentora MySQL database 
mysqldump -f sentora_core > /var/sentora/secured/uninstall/sentora_core.sql

#Sort out domains and their respective users
echo "Generating a list of domains and their owners now..."
sh ./ss_domains.sh
cp -f ./ss_users.sh /var/sentora/secured/

#Create Linux users
echo "Settings up new Linux users for jailed SFTP..."
sh ./ss_users.sh
cp -f ./ss_users.sh /var/sentora/secured/


#Backup the original FTP module
echo "Backing up the original Sentora FTP module to /etc/sentora/panel/modules/ftp_management/module.zpm-original"
mv /etc/sentora/panel/modules/ftp_management/module.zpm{,-original}
cp ./sftp_management/module.zpm /etc/sentora/panel/modules/ftp_management/module.zpm

#Fix insecure permissions
echo "Fixing insecure permissions..."
sh ./ss_permissions.sh
cp -f ../ss_permissions.sh /var/sentora/secured/

#Setup the cron to automatically update any changes
echo "A cron is now being setup to monitor over the server for any account changes."
echo -e "$(crontab -l)\n@hourly /bin/sh /var/sentora/secured/ss_cron.sh" | crontab -

#Backup the original sshd configuraiton
cp -a /etc/ssh/sshd_config /var/sentora/secured/uninstall/sshd_config
echo "Your original sshd configuration has been saved to /var/sentora/secured/uninstall/sshd_config"

##Get the SFTP jailed shell environment ready.
#Disable/comment-out possible conflicting entries in the SSH configuration file
echo "SSH is being modified to only allow jailed SFTP users and the root user."
sed -i s/Subsystem/\#Subsystem/g /etc/ssh/sshd_config
sed -i s/AllowUsers/\#AllowUsers/g /etc/ssh/sshd_config
sed -i s/AllowGroups/\#AllowGroups/g /etc/ssh/sshd_config
sed -i s/Match/\#Match/g /etc/ssh/sshd_config
sed -i s/ChrootDirectory/\#ChrootDirectory/g /etc/ssh/sshd_config
sed -i s/ForceCommand/\#ForceCommand/g /etc/ssh/sshd_config
sed -i s/X11Forwarding/\#X11Forwarding/g /etc/ssh/sshd_config
sed -i s/AllowTcpForwarding/\#AllowTcpForwarding/g /etc/ssh/sshd_config

#Enable jailed SFTP 
echo -e "Subsystem\tsftp\tinternal-sftp\nAllowGroups root sftpusers\nMatch Group sftpusers\n\tChrootDirectory %h\n\tForceCommand internal-sftp\n\tX11Forwarding no\n\tAllowTcpForwarding no" >> /etc/ssh/sshd_config;
service sshd restart

echo "Sentora Secured has been installed to /var/sentora/secured/"


