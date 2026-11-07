# Windows half of the RacecarSim relay.
#
# Started by relay_wsl.py through WSL interop. It carries RacecarSim's UDP datagrams over this
# process's stdin/stdout, so they never cross the WSL-Windows network, and talks to RacecarSim
# on 127.0.0.1, the path that is reliable.
#
# Frame format on the pipe: 1-byte channel (0 = sync port 5065, 1 = async port 5064),
# 4-byte big-endian length, then the datagram.
#
# Both sim channels share ONE UDP socket: RacecarSim remembers the endpoint a program
# connected from and ignores packets from any other. The process exits when stdin closes,
# so it never outlives the WSL half.
#
# Nothing may be written to stdout except frames.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$source = @'
using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Threading;

public static class RacecarSimRelay
{
    const int SyncPort = 5065;
    const int AsyncPort = 5064;
    // Stops Windows reporting an ICMP port-unreachable as an error on the next Receive.
    const int SIO_UDP_CONNRESET = -1744830452;

    public static void Run()
    {
        UdpClient udp = new UdpClient(new IPEndPoint(IPAddress.Loopback, 0));
        udp.Client.ReceiveBufferSize = 1 << 22;
        udp.Client.IOControl(SIO_UDP_CONNRESET, new byte[] { 0, 0, 0, 0 }, null);

        Stream stdin = Console.OpenStandardInput();
        Stream stdout = Console.OpenStandardOutput();

        Thread back = new Thread(() => SimToPipe(udp, stdout));
        back.IsBackground = true;
        back.Start();

        PipeToSim(udp, stdin);
    }

    static bool ReadExact(Stream s, byte[] buf, int n)
    {
        int off = 0;
        while (off < n)
        {
            int r = s.Read(buf, off, n - off);
            if (r <= 0) return false;
            off += r;
        }
        return true;
    }

    // Returns when the WSL half closes the pipe.
    static void PipeToSim(UdpClient udp, Stream stdin)
    {
        IPEndPoint sync = new IPEndPoint(IPAddress.Loopback, SyncPort);
        IPEndPoint asyncEp = new IPEndPoint(IPAddress.Loopback, AsyncPort);
        byte[] header = new byte[5];
        while (ReadExact(stdin, header, 5))
        {
            int length = (header[1] << 24) | (header[2] << 16) | (header[3] << 8) | header[4];
            byte[] payload = new byte[length];
            if (!ReadExact(stdin, payload, length)) return;
            udp.Send(payload, length, header[0] == 0 ? sync : asyncEp);
        }
    }

    static void SimToPipe(UdpClient udp, Stream stdout)
    {
        IPEndPoint from = new IPEndPoint(IPAddress.Any, 0);
        while (true)
        {
            byte[] payload;
            try { payload = udp.Receive(ref from); }
            catch (SocketException) { continue; }

            int channel = from.Port == SyncPort ? 0 : from.Port == AsyncPort ? 1 : -1;
            if (channel < 0) continue;

            byte[] frame = new byte[5 + payload.Length];
            frame[0] = (byte)channel;
            frame[1] = (byte)(payload.Length >> 24);
            frame[2] = (byte)(payload.Length >> 16);
            frame[3] = (byte)(payload.Length >> 8);
            frame[4] = (byte)payload.Length;
            Buffer.BlockCopy(payload, 0, frame, 5, payload.Length);
            try
            {
                stdout.Write(frame, 0, frame.Length);
                stdout.Flush();
            }
            catch (IOException) { Environment.Exit(0); }
        }
    }
}
'@

Add-Type -TypeDefinition $source -Language CSharp | Out-Null
[RacecarSimRelay]::Run()
[Environment]::Exit(0)
