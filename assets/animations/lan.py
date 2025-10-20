import os
import re

def scan_devices_using_arp():
    # Run 'arp -a' command to get ARP table
    result = os.popen('arp -a').read()
    
    # Parse IP and MAC addresses using regex
    devices = re.findall(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+([0-9A-Fa-f-]+)', result)
    
    print("Active devices on your WLAN:")
    print("----------------------------")
    print("IP Address\t\tMAC Address")
    print("----------------------------")
    for ip, mac in devices:
        print(f"{ip}\t\t{mac}")

if __name__ == "__main__":
    scan_devices_using_arp()