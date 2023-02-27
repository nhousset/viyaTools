import argparse
import socket
import ssl
import subprocess
import sys
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("host", type=str, help="")
parser.add_argument("port", type=int, help="")
args = parser.parse_args()

if sys.version_info[0] < 3:
    print("Error: Your Python interpreter must be version 3 or greater")
    exit()

class CasSocket:
    def __init__(self, host, port):
        self.cas = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.connect(host, port)

    def connect(self, host, port):
        self.cas.connect((host, port))
        self.send()

    def send(self):
        # build a valid TKCAL message (all integers are intel-byte order
        #    4 byte 'eyecatcher '\0SAC'  (byte swapped CAS\n)
        #    8 byte length of header+payload  (byte swapped)
        #    16 byte header
        #         4 byte header length  (16)
        #         4 byte flags (0)
        #         4 byte type (2 = REQUEST)
        #         4 byte tag (5 = STARTTLS )

        msg = bytearray([0, 0x53, 0x41, 0x43,
                         0x10, 0, 0, 0, 0, 0, 0, 0,
                         0x10, 0, 0, 0,
                         0, 0, 0, 0,
                         2, 0, 0, 0,
                         5, 0, 0, 0])
        self.cas.sendall(msg)

    def receive(self):
        msg = bytearray([])
        while len(msg) < 28:
            chunk = self.cas.recv(28 - len(msg))
            if chunk == b'':
                raise RuntimeError(
                    "Socket connection is broken. Please verify the host and port and make sure that you are connecting to the binary port of the CAS server.")
            msg = msg + chunk

        return msg

    def getValue(self, msg, offset, len):
        val = 0
        offset += len
        offset -= 1
        while len > 0:
            val *= 256
            val += msg[offset]
            offset -= 1
            len -= 1

        return val

    def close(self):
        self.cas.close()


def main():
    cas = CasSocket(args.host, args.port)
    msg = cas.receive()

    eye = cas.getValue(msg, 0, 4)
    totalSz = cas.getValue(msg, 4, 8)
    hdrSz = cas.getValue(msg, 12, 4)
    flags = cas.getValue(msg, 16, 4)
    type = cas.getValue(msg, 20, 4)
    tag = cas.getValue(msg, 24, 4)

    if eye != 0x43415300 or type != 3 or hdrSz != 16 or totalSz != 16:
        print(
            "Invalid response from the server. Please verify the host and port and make sure that you are connecting to the binary port of the CAS server.")

    if tag == 5:
        print("cas-shared-default up")
        
    elif tag == 7:
        print("Server is a CAS Binary port, but SSL is not configured")
    else:
        print("Server is a CAS Binary port, but an unexpected response type {} was received".format(tag))

    cas.close()


if __name__ == '__main__':
    main()
