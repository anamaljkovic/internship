#!/usr/bin/env python3

import argparse
import os
import socket
import subprocess


def getDistroInfo():
    name = subprocess.run(["sw_vers", "-productName"], capture_output=True, text=True).stdout.strip()
    version = subprocess.run(["sw_vers", "-productVersion"], capture_output=True, text=True).stdout.strip()
    return f"{name} {version}"


def getMemoryInfo():
    total_bytes = int(subprocess.run(
        ["sysctl", "-n", "hw.memsize"], capture_output=True, text=True
    ).stdout.strip())

    vm_stat_output = subprocess.run(["vm_stat"], capture_output=True, text=True).stdout

    page_size = 4096  
    pages_free = 0
    pages_inactive = 0

    for line in vm_stat_output.splitlines():
        if "page size of" in line:
            page_size = int(line.split("page size of")[1].split()[0])
        elif line.startswith("Pages free"):
            pages_free = int(line.split(":")[1].strip().rstrip("."))
        elif line.startswith("Pages inactive"):
            pages_inactive = int(line.split(":")[1].strip().rstrip("."))

    free_bytes = (pages_free + pages_inactive) * page_size
    used_bytes = total_bytes - free_bytes

    return {
        "total_mb": total_bytes // (1024 * 1024),
        "used_mb": used_bytes // (1024 * 1024),
        "free_mb": free_bytes // (1024 * 1024),
    }


def getCpuInfo():
    model = subprocess.run(
        ["sysctl", "-n", "machdep.cpu.brand_string"], capture_output=True, text=True
    ).stdout.strip()

    core_count = os.cpu_count()

    speed = "Unknown"
    freq_result = subprocess.run(
        ["sysctl", "-n", "hw.cpufrequency"], capture_output=True, text=True
    )
    if freq_result.returncode == 0 and freq_result.stdout.strip():
        speed_hz = int(freq_result.stdout.strip())
        speed = f"{speed_hz / 1_000_000_000:.2f} GHz"

    return {"model": model, "cores": core_count, "speed": speed}


def getCurrentUser():
    return os.getlogin()


def getLoadAverage():
    return os.getloadavg()


def getIpAddress():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = "127.0.0.1"
    finally:
        s.close()
    return ip


def main():
    parser = argparse.ArgumentParser(description="Display system information")
    parser.add_argument("-d", "--distro", action="store_true", help="Show distro info")
    parser.add_argument("-m", "--memory", action="store_true", help="Show memory info")
    parser.add_argument("-c", "--cpu", action="store_true", help="Show CPU info")
    parser.add_argument("-u", "--user", action="store_true", help="Show current user")
    parser.add_argument("-l", "--load", action="store_true", help="Show load average")
    parser.add_argument("-i", "--ip", action="store_true", help="Show IP address")

    args = parser.parse_args()

    show_all = not any([args.distro, args.memory, args.cpu, args.user, args.load, args.ip])

    if args.distro or show_all:
        print(f"Distro: {getDistroInfo()}")

    if args.memory or show_all:
        mem = getMemoryInfo()
        print(f"Memory: total={mem['total_mb']}MB used={mem['used_mb']}MB free={mem['free_mb']}MB")

    if args.cpu or show_all:
        cpu = getCpuInfo()
        print(f"CPU: model={cpu['model']} cores={cpu['cores']} speed={cpu['speed']}")

    if args.user or show_all:
        print(f"User: {getCurrentUser()}")

    if args.load or show_all:
        load1, load5, load15 = getLoadAverage()
        print(f"Load average: 1min={load1:.2f} 5min={load5:.2f} 15min={load15:.2f}")

    if args.ip or show_all:
        print(f"IP address: {getIpAddress()}")


main()