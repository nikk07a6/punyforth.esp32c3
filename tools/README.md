# Host tools

These tools connect to the BLE echo example and the TCP REPL example. Install
the Python dependencies from the repository root:

```bash
python3 -m pip install bleak prompt_toolkit
```

## BLE echo (`bt-echo`)

Copy `forth/core.fth`, `forth/bt.fth`, and `examples/bt-echo.fth` to the
device's `/f` filesystem. In the device REPL, start BLE advertising and the
echo word:

```forth
load: /f/core.fth
load: /f/bt.fth
"PunyForth" bt-start
load: /f/bt-echo.fth
bt-echo
```

Connect from the host with:

```bash
python3 tools/bt_console.py
```

By default, the tool scans for a device named `PunyForth`. Use `--name NAME`
or `--address AA:BB:CC:DD:EE:FF` to select a different device. Type a line to
send it; Ctrl-D or Ctrl-C disconnects the host client. The Forth word echoes
received bytes and exits when it receives byte `0x04`.

## TCP REPL (`tcp-repl`)

Copy `forth/core.fth`, `forth/tasks.fth`, `forth/network.fth`,
`forth/ringbuf.fth`, `forth/mailbox.fth`, and `examples/tcp-repl.fth` to `/f`.
In the device REPL, connect to Wi-Fi and start the server:

```forth
load: /f/core.fth
load: /f/tasks.fth
load: /f/network.fth
load: /f/ringbuf.fth
load: /f/mailbox.fth
wifi-init
"your-password" "your-ssid" wifi-connect
load: /f/tcp-repl.fth
repl-start
```

The device prints its IP address and listens on TCP port 1983. Connect from
the host using that address:

```bash
python3 tools/pftcp.py DEVICE_IP
```

Use Ctrl-A to enter a local file path and send that file to the device. Use
Ctrl-Q or Ctrl-E, then Enter, to disconnect.
