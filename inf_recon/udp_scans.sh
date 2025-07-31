#!/bin/bash

filename="$1"
mkdir -p scan_results/udp

nums=({000..999})
total_files=$( find . -type f -name "${filename}.[0-9][0-9][0-9]" | wc -l )

for ((c=0; c<${total_files}; c++ )); do 
    echo "Launching UDP scan $((c+1))/${total_files}"
    run_job sudo nmap -sU --top-ports=1000 --max-rtt-timeout=150ms --max-retries=3 -iL "${filename}.${nums[c]}" -Pn -oA scan_results/udp/udp-popular-ports-${nums[c]} 
done

echo "UDP scans launched, will notify on completion."
sleep 2

# check status of scans every 60 seconds
while true; do
    completed_udp=0
    for ((c=0; c<${total_files}; c++ )); do 
        if [[ $(grep "Nmap done" scan_results/udp/udp-popular-ports-${nums[c]}.nmap 2>/dev/null) ]]; then 
            ((completed_udp++))
        fi
    done

    echo "${completed_udp}/${total_files} UDP scans complete."

    if [[ $completed_udp -eq $total_files ]]; then
        echo "UDP scans complete, now proceeding with analysis."
        mkdir -p analysis/nmap_scan_data
        mkdir -p analysis/other_scan_data
        mv scan_results/udp/*.nmap analysis/nmap_scan_data
        mv scan_results/udp/udp-popular-ports* analysis/other_scan_data
        echo "Merging scan results into one file..."
        cat analysis/nmap_scan_data/udp-popular-ports* > analysis/nmap_scan_data/udp-pop-ports-${filename}.txt && echo "Merged UDP scan results."
        run_job ./udp_lists_by_svc.sh "${filename}" 
        stty echo
        exit 0
    fi

    sleep 60
done

stty echo
exit 0
