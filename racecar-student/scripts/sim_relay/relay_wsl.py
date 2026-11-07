"""WSL half of the RacecarSim relay.

RacecarSim runs on Windows and the student's Python runs in WSL. Large camera datagrams are
lost crossing the WSL-Windows network, in NAT mode a few frames in, and in mirrored mode
always. This relay avoids that network entirely:

    lab.py --UDP 127.0.0.1:5064/5065--> relay_wsl.py (WSL)
        --stdin/stdout of a WSL interop child--> relay_win.ps1 (Windows)
        --UDP 127.0.0.1--> RacecarSim.exe

Python must target 127.0.0.1 (RACECAR_SIM_IP=127.0.0.1, which racecar_core_sim already reads).
The protocol is passed through untouched; every datagram arrives whole.

Usage: python3 relay_wsl.py <path to relay_win.ps1 as a Windows path>
Prints "relay ready" once the sim ports are bound. Exits when the Windows half exits, and
closes the Windows half when it exits itself. Stops on SIGTERM or SIGHUP; ignores SIGINT.
"""
import os
import select
import signal
import socket
import struct
import subprocess
import sys

HEADER = struct.Struct("!BI")  # channel, length
SIM_PORTS = {0: 5065, 1: 5064}  # channel -> RacecarSim port (sync, async)


class Deframer:
    """Accumulates pipe bytes and yields complete (channel, payload) frames."""

    def __init__(self) -> None:
        self.buf = bytearray()

    def feed(self, data: bytes):
        self.buf += data
        while len(self.buf) >= HEADER.size:
            chan, length = HEADER.unpack_from(self.buf)
            end = HEADER.size + length
            if len(self.buf) < end:
                return
            payload = bytes(self.buf[HEADER.size:end])
            del self.buf[:end]
            yield chan, payload


def bind_sim_ports() -> dict:
    sockets = {}
    for chan, port in SIM_PORTS.items():
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 1 << 22)
        try:
            s.bind(("127.0.0.1", port))
        except OSError as e:
            sys.exit(f"relay: cannot bind 127.0.0.1:{port} ({e.strerror}); is another relay running?")
        sockets[chan] = s
    return sockets


def main(ps1_windows_path: str) -> None:
    sockets = bind_sim_ports()
    chan_of = {s: chan for chan, s in sockets.items()}

    child = subprocess.Popen(
        ["powershell.exe", "-NoLogo", "-NoProfile", "-NonInteractive",
         "-ExecutionPolicy", "Bypass", "-File", ps1_windows_path],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, bufsize=0,
    )

    def shutdown(*_):
        # Closing stdin is what ends the Windows half; terminate covers a stuck interop proxy.
        try:
            child.stdin.close()
        except OSError:
            pass
        try:
            child.wait(timeout=3)
        except subprocess.TimeoutExpired:
            child.terminate()
        sys.exit(0)

    for sig in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, shutdown)
    # Ctrl-C belongs to the student's program, which sends RacecarSim an exit message on it;
    # the relay must outlive that message, so it stops only when racecar sim terminates it.
    signal.signal(signal.SIGINT, signal.SIG_IGN)

    from_win = child.stdout.fileno()
    print("relay ready", flush=True)

    to_win = child.stdin.fileno()

    def write_all(data: bytes) -> None:
        # A raw pipe write may be partial; a short frame would desynchronise the stream.
        view = memoryview(data)
        while view:
            view = view[os.write(to_win, view):]

    deframer = Deframer()
    # The student program's (ip, port) per channel; replies on a channel go back to the
    # address that last sent on it, or to the most recent sender if that channel has none yet.
    clients = {}
    last_client = None
    while True:
        for r in select.select([from_win, *chan_of], [], [])[0]:
            if r == from_win:
                data = os.read(from_win, 1 << 20)
                if not data:
                    sys.exit(f"relay: Windows half exited (code {child.wait()})")
                for chan, payload in deframer.feed(data):
                    client = clients.get(chan, last_client)
                    if client:
                        sockets[chan].sendto(payload, client)
            else:
                chan = chan_of[r]
                payload, last_client = r.recvfrom(65535)
                clients[chan] = last_client
                try:
                    write_all(HEADER.pack(chan, len(payload)) + payload)
                except BrokenPipeError:
                    sys.exit(f"relay: Windows half exited (code {child.wait()})")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
