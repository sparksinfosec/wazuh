#!/bin/bash 

###################
# Author: Steve Sparks 
# Created: 12/16/2025
# Upgrades existing wazuh agent and enrolls in new wazuh cluster
###################

# yum or dnf remove wazuh agent and filebeat 
# rpm -ivh wazuh-agent-4.12.0.1.x86_64.rpm
# Place the ossec.conf and authd.pass
# Set permissions and ownership 
# enable the service and start the service
# remove the password file (check to make sure auth was completed - /var/ossec/etc/client.keys #Check and store RHEL version number 
# Refinements 
# Pull the install and systemctl enable into a function? 
# Some kind of check/breakexit for each steps?
# Script in its current state is pretty safe but what if one of the function fails it would still install and enable without any check
# rsyslog.conf (make sure to disable rsyslog 
# Restart the service 
RHEL_VERSION=$(cat /etc/redhat-release | grep -oP 'release \K[\d\.]+' | cut -d'.' -f1)
# Can look at useless form of cat and just update with grep the specific files directly then cut should work the same
DC=$1 
# Write a check for the input and DC env to use
if [[ "$1" == "dcenv" || "$1" == "dcenv" ]];then 
	echo "Starting Script"
else
	echo "Exiting required argument '***' or '***' need to be passed"
	exit 1
fi


remove_filebeat(){
	local pkg="filebeat"
	if rpm -q "$pkg" &> /dev/null;then
        systemctl stop filebeat.service
		yum remove -y "$pkg"
	else
		echo "Filebeat not on system"
	fi
}
remove_syslog(){ # Note ISSUES IF more than one data center exist
    local config_file="/etc/rsyslog.conf"
    if grep -En "dcenv|dcenv" /etc/rsyslog.conf;then 
        echo "Updating RSYSLOG.CONF"
        line_num=$(grep -En "dcenv|dcenv" "$config_file" | cut -d':' -f1)
        sed -i "${line_num}s/^/#/" "$config_file"
	echo
	tail $config_file
	echo
    else
        echo "$config_file not showing dcenv or dcenv"
    fi
}
syslog_restart(){ 
    systemctl restart rsyslog.service 
}
remove_wazuh_agent(){
	local pkg="wazuh-agent"
	if rpm -q "$pkg" &> /dev/null;then
		yum remove -y "$pkg"
	else
		echo "Wazuh-agent not on system"
	fi 
}
wazuh_agent_install(){
    echo "Installing Agent 4.12" # Specific to this install
    rpm -ivh ./wazuh-agent.rpm 
}
password_files(){
	cp ./authd.pass /var/ossec/etc/
	chown 640 /var/ossec/etc/authd.pass
	chown root:wazuh /var/ossec/etc/authd.pass
	ls -al /var/ossec/etc/authd.pass
}
config_file(){
	cp /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.BAK.conf
	if [[ $RHEL_VERSION = 7 ]];then
		cp ./"$DC"-ossec"$RHEL_VERSION".conf /var/ossec/etc/ossec.conf
	elif [[ $RHEL_VERSION = 8 ]];then
		cp ./"$DC"-ossec"$RHEL_VERSION".conf /var/ossec/etc/ossec.conf
	elif [[ $RHEL_VERSION = 9 ]];then 
		cp ./"$DC"-ossec"$RHEL_VERSION".conf /var/ossec/etc/ossec.conf 
	else 
		echo "Config file not moved"
	fi
}
wazuh_agent_restart(){
    systemctl daemon-reload
    systemctl enable --now wazuh-agent 
    systemctl status wazuh-agent --no-pager
    systemctl status filebeat.service --no-pager
    systemctl status rsyslog.service --no-pager
}
cleanup(){
	local check_file="/var/ossec/etc/client.keys"
	local max_checks=20
	local counter=0

	until [ -s "$check_file" ] || [ "$counter" -ge "$max_checks" ]; do
		if [ ! -f "$check_file"	];then 
			echo "Client Keys are empty"
			break
		fi
	sleep 5 
	((counter++))
done
	if [ -s "$check_file" ];then 
		echo "Client key populated removing password file"
		rm -f /var/ossec/etc/authd.pass
	else 
		echo "Timeout" 
		echo "Password file not removed"
	fi
}

remove_filebeat
remove_syslog
syslog_restart
remove_wazuh_agent
wazuh_agent_install
password_files
config_file 
wazuh_agent_restart
cleanup





    
 
 
