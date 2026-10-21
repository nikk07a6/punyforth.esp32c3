#!/usr/bin/env python3
"""
Minimal BLE console for a Punyforth device exposing the Nordic UART Service.

Install:
    pip install --user bleak

Usage:
    python3 tools/bt_console.py                       # scan for "PunyForth"
    python3 tools/bt_console.py --name MyDevice
    python3 tools/bt_console.py --address AA:BB:CC:DD:EE:FF

Type a line and press Enter to send to the device. Notifications from the
device are printed to stdout as they arrive. Ctrl-D or Ctrl-C to quit.
"""

import argparse
import asyncio
import sys
from contextlib import suppress

from bleak import BleakClient, BleakScanner

NUS_SVC = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
NUS_RX_CHAR = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"  # host -> device (write)
NUS_TX_CHAR = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"  # device -> host (notify)

DEFAULT_NAME = "PunyForth"


async def find_device(name=None, address=None, timeout=10.0):
    if address:
        return await BleakScanner.find_device_by_address(address, timeout=timeout)
    target = name or DEFAULT_NAME
    print(f"Scanning for '{target}' (timeout {timeout:.0f}s)...", file=sys.stderr)
    return await BleakScanner.find_device_by_name(target, timeout=timeout)


def on_notify(_sender, data: bytearray):
    try:
        sys.stdout.write(data.decode("utf-8", errors="replace"))
    except Exception:
        sys.stdout.write(repr(bytes(data)))
    sys.stdout.flush()


async def stdin_pump(client: BleakClient):
    loop = asyncio.get_running_loop()
    mtu = getattr(client, "mtu_size", 23) or 23
    chunk = max(20, mtu - 3)
    while True:
        line = await loop.run_in_executor(None, sys.stdin.readline)
        if not line:
            return
        payload = line.encode("utf-8")
        for off in range(0, len(payload), chunk):
            await client.write_gatt_char(
                NUS_RX_CHAR, payload[off:off + chunk], response=False
            )


async def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    ap.add_argument("--name", help=f"device name (default '{DEFAULT_NAME}')")
    ap.add_argument("--address", help="exact BLE MAC, skips scanning")
    ap.add_argument("--timeout", type=float, default=10.0, help="scan timeout, s")
    args = ap.parse_args()

    dev = await find_device(args.name, args.address, args.timeout)
    if dev is None:
        print("Device not found.", file=sys.stderr)
        return 1

    print(f"Connecting to {dev.address} ({dev.name})...", file=sys.stderr)
    async with BleakClient(dev) as client:
        await client.start_notify(NUS_TX_CHAR, on_notify)
        mtu = getattr(client, "mtu_size", None)
        if mtu:
            print(f"Connected, MTU={mtu}. Type to send, Ctrl-D to quit.",
                  file=sys.stderr)
        else:
            print("Connected. Type to send, Ctrl-D to quit.", file=sys.stderr)
        try:
            await stdin_pump(client)
        finally:
            with suppress(Exception):
                await client.stop_notify(NUS_TX_CHAR)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(asyncio.run(main()) or 0)
    except KeyboardInterrupt:
        pass
