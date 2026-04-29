#!/usr/bin/env python3
"""
RACECAR Neo Connection Diagnostics

Tests the networking path between WSL2/Linux and the RacecarNeo Simulator.
Run this script to debug connectivity issues before launching the simulator.

Usage:
    python3 diagnose.py
"""

import socket
import subprocess
import os
import sys


def resolve_sim_ip():
    """Resolve the simulator IP using the same logic as racecar_core_sim.py."""
    env_ip = os.environ.get("RACECAR_SIM_IP")
    if env_ip:
        return env_ip, "RACECAR_SIM_IP env var"

    # Check if we are running in WSL2
    is_wsl2 = False
    try:
        with open("/proc/version") as f:
            is_wsl2 = "microsoft" in f.read().lower()
    except OSError:
        pass

    if not is_wsl2:
        return "127.0.0.1", "localhost (not WSL2)"

    # In WSL2: read default gateway from /proc/net/route
    try:
        with open("/proc/net/route") as f:
            for line in f:
                fields = line.strip().split()
                if fields[1] == "00000000":
                    hex_ip = fields[2]
                    ip = ".".join(
                        str(int(hex_ip[i : i + 2], 16)) for i in range(6, -1, -2)
                    )
                    # Hyper-V NAT gateways live in 172.16.0.0/12
                    first_octet = int(hex_ip[6:8], 16)
                    second_octet = int(hex_ip[4:6], 16)
                    if first_octet == 172 and 16 <= second_octet <= 31:
                        return ip, "WSL2 NAT mode (Hyper-V gateway)"
                    # Gateway outside Hyper-V range — likely mirrored mode
                    return "127.0.0.1", "WSL2 mirrored mode (localhost)"
    except (OSError, IndexError, ValueError):
        pass

    return "127.0.0.1", "fallback (localhost)"


def check_ping(ip):
    """Test ICMP ping to the simulator host."""
    try:
        result = subprocess.run(
            ["ping", "-c", "1", "-W", "2", ip],
            capture_output=True,
            timeout=5,
        )
        return result.returncode == 0
    except Exception:
        return False


def check_udp_port(ip, port):
    """Test UDP send/receive on a specific port."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.settimeout(2)
        # Send a connect packet (Header.connect=1, version=1)
        s.sendto(b"\x01\x01", (ip, port))
        send_ok = True
        try:
            data, addr = s.recvfrom(8)
            response = (addr, data.hex())
        except socket.timeout:
            response = None
        s.close()
        return send_ok, response
    except Exception as e:
        return False, str(e)


def check_local_bind():
    """Test that we can bind a local UDP socket."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.bind(("0.0.0.0", 0))
        addr = s.getsockname()
        s.close()
        return True, addr
    except Exception as e:
        return False, str(e)


def check_firewall_rule():
    """Check if the Windows Firewall rule exists (WSL2 only)."""
    try:
        result = subprocess.run(
            [
                "powershell.exe",
                "-Command",
                'Get-NetFirewallRule -DisplayName "WSL2 RacecarNeo Simulator" '
                "-ErrorAction SilentlyContinue | "
                "Select-Object -ExpandProperty Enabled",
            ],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if "True" in result.stdout:
            return "enabled"
        elif "False" in result.stdout:
            return "disabled"
        else:
            return "not_found"
    except FileNotFoundError:
        return "not_wsl"
    except Exception as e:
        return f"error: {e}"


def check_wsl_adapter():
    """Get the WSL network adapter name from Windows."""
    try:
        result = subprocess.run(
            [
                "powershell.exe",
                "-Command",
                "Get-NetAdapter -IncludeHidden | "
                "Where-Object { $_.Name -like '*WSL*' } | "
                "Format-Table Name,Status -AutoSize",
            ],
            capture_output=True,
            text=True,
            timeout=10,
        )
        return result.stdout.strip() if result.stdout.strip() else None
    except FileNotFoundError:
        return None
    except Exception:
        return None


def main():
    print("=== RACECAR Neo Connection Diagnostics ===")
    print()

    issues = []

    # 1. Resolve simulator IP
    sim_ip, ip_source = resolve_sim_ip()
    print(f"[1] Simulator IP: {sim_ip} (source: {ip_source})")
    if sim_ip == "127.0.0.1" and ip_source == "fallback (localhost)":
        issues.append(
            "Could not detect WSL2 gateway — if on WSL2, the simulator may not connect."
        )

    # 2. Ping test
    if check_ping(sim_ip):
        print(f"[2] Ping to {sim_ip}: OK")
    else:
        print(f"[2] Ping to {sim_ip}: FAILED (may be normal if ICMP is blocked)")

    # 3. UDP send test
    for port in [5064, 5065]:
        send_ok, response = check_udp_port(sim_ip, port)
        if send_ok:
            print(f"[3] UDP send to {sim_ip}:{port}: OK (packet sent)")
            if response:
                addr, data = response
                print(f"    Response from {addr}: {data} (simulator is running!)")
            else:
                print(f"    No response (expected if simulator is not running)")
        else:
            print(f"[3] UDP send to {sim_ip}:{port}: FAILED ({response})")
            issues.append(f"Cannot send UDP to port {port}")

    # 4. Local UDP bind
    bind_ok, bind_info = check_local_bind()
    if bind_ok:
        print(f"[4] Local UDP bind: OK (bound to {bind_info[0]}:{bind_info[1]})")
    else:
        print(f"[4] Local UDP bind: FAILED ({bind_info})")
        issues.append("Cannot bind local UDP socket")

    # 5. Windows Firewall rule
    fw_status = check_firewall_rule()
    if fw_status == "enabled":
        print("[5] Windows Firewall rule: FOUND (enabled)")
    elif fw_status == "disabled":
        print("[5] Windows Firewall rule: FOUND (but DISABLED)")
        issues.append("Firewall rule exists but is disabled")
    elif fw_status == "not_found":
        print(
            "[5] Windows Firewall rule: NOT FOUND — run the PowerShell command from setup"
        )
        issues.append("Windows Firewall rule not configured")
    elif fw_status == "not_wsl":
        print("[5] Windows Firewall rule: N/A (not running in WSL2)")
    else:
        print(f"[5] Windows Firewall rule: Could not check ({fw_status})")

    # 6. WSL adapter info
    adapter_info = check_wsl_adapter()
    if adapter_info:
        print(f"[6] WSL network adapter:")
        for line in adapter_info.splitlines():
            if line.strip():
                print(f"    {line}")
    else:
        print("[6] WSL network adapter: N/A (not running in WSL2)")

    # Summary
    print()
    if not issues:
        print("=== No issues detected ===")
        print(
            "If the simulator still won't connect, make sure it is running on the host"
        )
        print("and try running: racecar sim demo.py")
    else:
        print(f"=== {len(issues)} potential issue(s) found ===")
        for i, issue in enumerate(issues, 1):
            print(f"  {i}. {issue}")
        print()
        print("Share this output with your instructor for help.")

    return 0 if not issues else 1


if __name__ == "__main__":
    sys.exit(main())
