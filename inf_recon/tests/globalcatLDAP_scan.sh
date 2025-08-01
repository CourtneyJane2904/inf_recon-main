#!/bin/bash

# https://book.hacktricks.xyz/network-services-pentesting/pentesting-ftp
host=$1
port=21
dest_dir="svc_scan_results/${host}/globalcatLDAP"
mkdir -p "${dest_dir}"

if [[ ! -z "${2}" ]]; then
	port=$2
fi

echo "Launching globalcatLDAP scans on ${host}:${port}"

# enumeration with nmap
# run default nmap scripts for ftp and retrieve version
run_job nmap -Pn -sV --script "ldap* and not brute" "${host}" -p "${port}" -oN "${dest_dir}/enum_p${port}"

echo "FTP scans on ${host}:${port} launched."
exit 0
