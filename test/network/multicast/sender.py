import socket

MCAST_GRP = "224.0.1.1"
MCAST_PORT = 30001

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)

# Enable multicast TTL (how far packets travel)
ttl = 1  # 1 = local network only
sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, ttl)

print(f"Sending messages to {MCAST_GRP}:{MCAST_PORT} ...")

while True:
    msg = input("Enter message: ").encode()
    sock.sendto(msg, (MCAST_GRP, MCAST_PORT))
    print("Sent!")
