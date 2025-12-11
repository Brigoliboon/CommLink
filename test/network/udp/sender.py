import socket
import time

UDP_IP = "10.0.0.174"   # ← CHANGE THIS to receiver’s IP
UDP_PORT = 30002

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

while True:
    msg = "Hello from sender!"
    sock.sendto(msg.encode('utf-8'), (UDP_IP, UDP_PORT))
    print(f"Sent: {msg}")
    time.sleep(1)
