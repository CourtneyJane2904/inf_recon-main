#!/bin/bash

filename="$1"
mkdir -p scan_results/tcp

# adjust if more than 6400 hosts need to be scanned
nums=({000..999})
total_files=$( find . -type f -name "${filename}.[0-9][0-9][0-9]" | wc -l )

for ((c=0; c<${total_files}; c++)); do 
    echo "Launching TCP scan $((c+1))/${total_files}"
    run_job nmap -sS --max-rtt-timeout=150ms --max-retries=3 -T4 -p- -iL "${filename}".${nums[c]} -Pn -oA scan_results/tcp/tcp-all-ports-${nums[c]} 
done

echo "TCP scans launched, will notify on completion."
sleep 2

# Check status of scans every 60 seconds
while true; do
    completed_tcp=0
    for ((ch=0; ch<${total_files}; ch++)); do 
        if [[ $(grep "Nmap done" scan_results/tcp/tcp-all-ports-${nums[ch]}.nmap 2>/dev/null) ]]; then 
            ((completed_tcp++))
        fi
    done

    echo "${completed_tcp}/${total_files} TCP scans complete."

    if [[ $completed_tcp -eq $total_files ]]; then
        echo "TCP scans complete."
        mkdir -p analysis/nmap_scan_data
        mkdir -p analysis/other_scan_data
        mv scan_results/tcp/*.nmap analysis/nmap_scan_data
        mv scan_results/tcp/tcp-all-ports* analysis/other_scan_data
        echo "Merging scan results into one file..."
        cat analysis/nmap_scan_data/tcp-all-ports* > analysis/nmap_scan_data/tcp-all-ports-${filename}.txt && echo "Merged TCP scan results."

        # Aggressive Scan Phase
        echo "Starting aggressive scans on discovered hosts..."
        mkdir -p scan_results/tcp/aggressive

        # Extract IPs directly (handles hostname + IP cases)
        grep "Nmap scan report for" analysis/nmap_scan_data/tcp-all-ports-${filename}.txt \
        | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' > analysis/discovered_hosts.txt

        while read ip; do
            # Skip if no IP found
            [[ -z "$ip" ]] && continue

            # Extract open ports for this IP
            open_ports=$(grep -A100 "$ip" analysis/nmap_scan_data/tcp-all-ports-${filename}.txt \
                | grep open | cut -d '/' -f1 | tr '\n' ',' | sed 's/,$//')

            if [[ -n "$open_ports" ]]; then
                echo "Aggressive scan on $ip (ports: $open_ports)"
                run_job nmap -A -p "$open_ports" "$ip" -oA scan_results/tcp/aggressive/tcp-aggressive-${ip//./-}
            fi
        done < analysis/discovered_hosts.txt

        run_job ./tcp_lists_by_svc.sh "${filename}" 
        stty echo
        exit 0
    fi

    sleep 60
done

stty echo
exit 0
