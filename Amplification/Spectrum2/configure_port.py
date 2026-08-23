import os
port = 0
speed = 100000 #100G

for port in range (0, 128, 4):
    print("sudo config interface speed Ethernet%d %d" %(port, speed))
    os.system("sudo config interface speed Ethernet%d %d" %(port, speed))
