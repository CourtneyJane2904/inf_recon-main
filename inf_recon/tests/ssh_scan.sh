#!/bin/bash

# https://book.hacktricks.xyz/network-services-pentesting/pentesting-ssh
host=$1
port=22
dest_dir="svc_scan_results/${host}/ssh"
mkdir -p "${dest_dir}"
ssh_creds="wordlists/ssh_default_creds.txt"

if [[ ! -z "${2}" ]]; then
	port=$2
fi

echo "Launching SSH scans on ${host}:${port}"

# enumeration with nmap
# run default nmap -Pn scripts for SSH and retrieve version
timeout 5 nc -vn "${host}" "${port}" > "${dest_dir}/banner_p${port}" 
run_job nmap -Pn -p${port} $host -sCV -oA "${dest_dir}/general_p${port}"
run_job nmap -Pn --script ssh2-enum-algos -p${port} $host -oA "${dest_dir}/weak_kex_algos_p${port}"
run_job nmap -Pn -p${port} $host --script ssh-hostkey --script-args ssh_hostkey=full -oA "${dest_dir}/weak_keys_p${port}"
run_job nmap -Pn -p${port} $host --script ssh-auth-methods --script-args="ssh.user=root" -oA "${dest_dir}/auth_methods_p${port}"
# run_job nmap -p${port} $host --script ssh-brute -oA "${dest_dir}/nmap_brute_p${port}"
run_job hydra -C "${ssh_creds}" -s "${port}" -o "${dest_dir}/hydra_brute_p${port}" "${host}" ssh

echo "SSH scans on ${host}:${port} launched."
exit 0
