import socket
import struct

MCAST_GRP = "224.0.1.1"
MCAST_PORT = 30001

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

sock.bind(("", MCAST_PORT))

# Join multicast group
mreq = struct.pack(
    "4sl",
    socket.inet_aton(MCAST_GRP),
    socket.INADDR_ANY
)
sock.setsockopt(
    socket.IPPROTO_IP,
    socket.IP_ADD_MEMBERSHIP,
    mreq
)

print(f"Listening on multicast {MCAST_GRP}:{MCAST_PORT} ...")

while True:
    data, addr = sock.recvfrom(4096)
    print(f"Received from {addr}: {len(data)} bytes → {data[:50]!r}")
