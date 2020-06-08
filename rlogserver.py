# created by Tonyk7
import logging
import socket

# change this to match the port in RemoteLog.h
rlog_port = 11909

# code is from: https://gist.github.com/majek/1763628
def udp_server(host="192.168.0.146", port=rlog_port):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((host, port))

    while True:
        (data, addr) = s.recvfrom(128*1024)
        yield data

print("Listening")
for data in udp_server():
    print(data.decode('utf-8').strip())
