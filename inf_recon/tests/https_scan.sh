#!/bin/bash

# https://book.hacktricks.xyz/network-services-pentesting/pentesting-web
host=$1
port=443
dest_dir="svc_scan_results/${host}/https"
mkdir -p "${dest_dir}"
testssl=$(locate testssl.sh | head -n 1)

if [[ ! -z "${2}" ]]; then
	port=$2
fi

echo "Launching HTTPS scans on ${host}:${port}"

# enumeration with nmap
openssl s_client -connect ${host}:${port} -crlf -quiet > "${dest_dir}/${host}/banner_p${port}" &
# run default nmap scripts for ftp and retrieve version
run_job nmap -Pn -p${port} $host -sCV -oA "${dest_dir}/general_p${port}"
run_job "${testssl}" "https://${host}:${port}" > "${dest_dir}/ssl_issues_p${port}"
run_job whatweb -a 3 "https://${host}:${port}" > "${dest_dir}/whatweb_enum_p${port}"
run_job nikto -h "https://${host}:${port}/" -nointeractive -maxtime 360 >> "${dest_dir}/nikto_enum_p${port}"
run_job timeout 360 gobuster -r -u "https://${host}:${port}/" -w wordlists/small_dir_list.txt -t 40 -x .js,.js.map,.txt > "${dest_dir}/pages_found_p${port}"
echo "HTTPS scans on ${host}:${port} launched."
exit 0
