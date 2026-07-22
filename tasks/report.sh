#!/opt/homebrew/bin/bash

report_file="system_report_$(date +%Y%m%d_%H%M%S).txt"
USE_SUDO_FREQUENCY=false

os_type=$(uname -s)

{
    echo "System Report"
    echo ""

    echo "Date and Time: $(date)"
    echo ""

    echo "Current User: $(whoami)"

    if [[ "$os_type" == "Darwin" ]]; then
        echo "Internal IP Address: $(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)"
        echo "Hostname: $(hostname)"

        echo "External IP Address: $(curl -s ifconfig.me)"

        echo "OS Name and Version:"
        echo "  $(sw_vers -productName) $(sw_vers -productVersion)"

        echo "System Uptime:"
        echo "  $(uptime | sed 's/.*up //' | sed 's/, [0-9]* users.*//')"

        echo "Disk Space (/ in GB):"
        df -g / | awk 'NR==2 {print "  Used: "$3"G  Free: "$4"G  Total: "$2"G"}'

        echo "RAM:"
        total_ram=$(sysctl -n hw.memsize)
        total_gb=$((total_ram / 1024 / 1024 / 1024))
        free_pages=$(vm_stat | awk '/Pages free/ {print $3}' | tr -d '.')
        page_size=$(vm_stat | head -1 | grep -o '[0-9]*')
        free_gb=$(( (free_pages * page_size) / 1024 / 1024 / 1024 ))
        echo "  Total: ${total_gb} GB"
        echo "  Free: ${free_gb} GB"

        echo "CPU Info:"
        cpu_cores=$(sysctl -n hw.ncpu)
        cpu_brand=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
        echo "  Cores: $cpu_cores"
        echo "  CPU Model: $cpu_brand"

        cpu_freq=$(sysctl -n hw.cpufrequency_max 2>/dev/null)
        if [[ -n "$cpu_freq" ]]; then
            echo "  Frequency: $((cpu_freq / 1000000)) MHz"
        elif [[ "$USE_SUDO_FREQUENCY" == true ]]; then
            if sudo -n true 2>/dev/null; then
                freq_info=$(sudo -n powermetrics -i 200 -n 1 --samplers cpu_power 2>/dev/null | grep -i "frequency")
                if [[ -n "$freq_info" ]]; then
                    echo "  Live Frequency (via powermetrics):"
                    echo "$freq_info" | sed 's/^/    /'
                else
                    echo "  Frequency: N/A (powermetrics returned no data)"
                fi
            else
                echo "  Frequency: N/A (no cached sudo session — run 'sudo -v' first to enable live frequency)"
            fi
        else
            echo "  Frequency: N/A (Apple Silicon doesn't expose a fixed frequency via sysctl)"
        fi

    else
        

        echo "Internal IP Address: $(hostname -I | awk '{print $1}')"
        echo "Hostname: $(hostname)"

        echo "External IP Address: $(curl -s ifconfig.me)"

        echo "Linux Distribution:"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            echo "  $NAME $VERSION"
        else
            echo "  Unknown"
        fi

        echo "System Uptime: $(uptime -p)"

        echo "Disk Space (/ in GB):"
        df -BG / | awk 'NR==2 {print "  Used: "$3"  Free: "$4"  Total: "$2}'

        echo "RAM (Total/Free):"
        free -h | awk 'NR==2 {print "  Total: "$2"  Free: "$4}'

        echo "CPU Info:"
        cpu_cores=$(nproc)
        echo "  Cores: $cpu_cores"

        if [[ "$USE_SUDO_FREQUENCY" == true ]]; then
            cpu_freq=$(lscpu | grep "MHz" | head -1 | awk '{print $NF}')
            echo "  Frequency: ${cpu_freq} MHz"
        else
            echo "  Frequency: (skipped — set USE_SUDO_FREQUENCY=true to show it)"
        fi
    fi

} > "$report_file"

echo "Report generated: $report_file"