#!/bin/bash

# https://book.hacktricks.xyz/network-services-pentesting/pentesting-smb
host=$1
port=445
dest_dir="svc_scan_results/${host}/microsoft-ds"
mkdir -p "${dest_dir}"
ssh_creds="wordlists/ssh_default_creds.txt"

if [[ ! -z "${2}" ]]; then
	port=$2
fi

echo "Launching SMB scans on ${host}:${port}"

# enumeration with nmap
# run default nmap scripts for ftp and retrieve version
run_job nmap -Pn -p${port} $host -sCV -oA "${dest_dir}/general_p${port}"
run_job nmap -Pn --script "safe or smb-enum-* or smb-vuln*" -p "${port}" "${host}" -oA "${dest_dir}/nmap_enum_p${port}"
run_job nmap -Pn --script smb-enum-users -p "${port}" "${host}" -oA "${dest_dir}/nmap_users_enum_p${port}"
run_job timeout 300s enum4linux -a "${host}" > "${dest_dir}/enum4linux_p${port}"
run_job hydra -t 1 -V -f -o "${dest_dir}/hydra_p${port}" -C ${ssh_creds} $ip smb
echo "SMB scans on ${host}:${port} launched."
exit 0
