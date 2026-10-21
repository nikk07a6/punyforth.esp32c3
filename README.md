# Punyforth (ESP32-C3)

A stack-based Forth for the ESP32-C3 (RISC-V). This is a port of [Punyforth](https://github.com/zeroflag/punyforth): an assembly inner interpreter, thin ESP-IDF wrappers in C, and Forth libraries on top.

After flashing, a REPL appears on UART (USB-CDC). The banner includes the project version configured in `CMakeLists.txt`:

```
Punyforth (ESP32-C3), version <project version>
```

A cell is 32 bits. The dictionary lives in RAM (64 KB heap). Cooperative multitasking, exceptions, FAT on SPI flash, Wi‑Fi, sockets, BLE UART, GPIO, ADC, 1-Wire, and WS2812 are available.

## Features

- UART REPL; Bluetooth LE Nordic UART Service (NUS) data interface
- FATFS on the `storage` partition, mounted at `/f`
- Dictionary snapshot in `/f/dict.bin` (`save-dict`) and reload on boot
- GPIO, interrupts, buttons, rotary encoder, event queue
- Wi‑Fi STA/AP, DNS, TCP/UDP, ICMP ping
- BLE NimBLE (can run together with Wi‑Fi)
- Oneshot ADC with on-chip calibration
- Dallas 1-Wire / DS18B20
- Addressable LED strips (RMT, `led_strip`)
- NTP (`time.nist.gov`)

## Requirements

- ESP32-C3 (for example a USB DevKit)
- [ESP-IDF](https://docs.espressif.com/projects/esp-idf/) (this tree has been built with IDF 6.x)
- USB-UART for the console
- Python 3 and `prompt_toolkit` for the TCP terminal (`tools/pftcp.py`)
- Python 3 + [bleak](https://github.com/hbldh/bleak) — only for `tools/bt_console.py`

## Build and flash

```bash
. $IDF_PATH/export.sh
idf.py set-target esp32c3
idf.py build
idf.py -p /dev/ttyACM0 flash monitor
```

NimBLE is already enabled in `sdkconfig.defaults`. Dependencies from `main/idf_component.yml` (`led_strip`, `onewire_bus`) are fetched into `managed_components/` on the first build.

## Flash layout

`partitions.csv`:

| Name     | Type    | Offset   | Size    | Purpose                             |
|----------|---------|----------|---------|-------------------------------------|
| nvs      | nvs     | 0x9000   | 24 KB   | Wi‑Fi and other IDF settings        |
| phy_init | phy     | 0xf000   | 4 KB    | PHY calibration                     |
| factory  | app     | 0x10000  | 1536 KB | firmware                            |
| storage  | fat     | 0x190000 | 2496 KB | Forth files (`/f/...`)              |

On boot `app_main` calls `forth_start()`:

1. Mount FAT at `/f` (`mount-fat-spiflash`). If the volume is missing, it is formatted.
2. If `/f/dict.bin` exists, load it into the heap and run `boot!`.
3. Otherwise enter the outer interpreter (REPL).

The firmware does not embed the sources in `forth/`; copy them onto FAT once.

## Using the REPL

The console is USB-UART. The default prompt is a space; after `stack-show` (which `core.fth` installs) the data stack is printed.

```forth
1 2 + . cr          \ 3
help                \ list words in the dictionary
freemem . cr        \ free heap
```

Comments: `( ... )` and `\ ...` to end of line.

Literals (besides decimal integers):

- quoted strings: `"text"` or `print: "text"`
- C-style hex: tokens starting with `0x` (`0xCC`, `0x001000`)
- character literals: `$` plus one character (`$A` is 65, `$: ` is 58)

```forth
0x10 . cr           \ 16
$A emit cr          \ A
":" type  $: emit   \ both print a colon
```

### UART terminal: `pfterm`

The UART terminal is maintained in the separate
[pfterm repository](https://github.com/nikk07a6/pfterm).

### Files on `/f`

```forth
ls: /f
upload: /f/core.fth     \ then paste the file; terminator is a /EOF line
load: /f/core.fth
rm: /f/old.fth
```

`upload:` writes console bytes until a line that starts with `/EOF`. Sources in this repo already end with `/EOF`.

Typical first session: load `forth/core.fth`, then the modules you need.

```forth
load: /f/core.fth
load: /f/tasks.fth
load: /f/network.fth
load: /f/ntp.fth
load: /f/bt.fth
```

### Saving the dictionary

After loading the required modules and defining any startup word, use `boot!` to
select the word that should run after the saved dictionary is loaded on restart.
Then run `save-dict` to write the dictionary and startup word to `/f/dict.bin`:

```forth
' my-startup boot!
save-dict
```

`core.fth` already sets `stack-show` as the startup word by default.

`marker:` rolls the dictionary back to a named point (`marker: xxx` … `xxx`).

`abort` restarts the chip (`esp_restart`).

## Repository layout

```
CMakeLists.txt          ESP-IDF project
partitions.csv
sdkconfig.defaults      NimBLE
main/
  main.c                app_main
  punyforth.S           inner interpreter, startup
  primitives.S          stack, arithmetic, branches
  words.S               colon words (load:, save-dict, …)
  api.S                 ESP-IDF primitives
  data.S                heap, stacks, strings
  forth_io.c            UART, FAT, GPIO, buttons, encoder, LED
  forth_net.c           Wi‑Fi, sockets, ping
  forth_bt.c            BLE NUS
  forth_1wire.c
  forth_adc.c
forth/                  Forth libraries (copy onto /f)
examples/               standalone Forth examples
tests/                  Forth unit tests
tools/
  bt_console.py         host BLE console
  pftcp.py              host TCP REPL terminal
  README.md             host tools instructions
```

Layers:

| Layer | Where | Role |
|-------|-------|------|
| VM | `punyforth.S`, `primitives.S`, `words.S` | threaded code, dictionary |
| C API | `forth_*.c` + `api.S` | drivers as Forth primitives |
| Forth | `forth/*.fth` | syntax, Wi‑Fi, NTP, ADC, 1-Wire |

## Forth modules

Copy files from `forth/` onto `/f` (`upload:` or any FAT tool) and `load:` them.
For VS Code syntax highlighting of `.fth` files, see
[editors/vscode](./editors/vscode/README.md).

### `core.fth`

Control flow (`if`/`else`/`then`, `begin`/`until`/`again`/`while`/`repeat`, `do`/`loop`, `case`), variables, exceptions, `print:`, `marker:`, `upload:`/`ls:`/`rm:`, stack prompt, GPIO and event constants, task records, and `next-event`.

### `tasks.fth`

Cooperative tasks (not FreeRTOS tasks). `pause` yields to another task.

```forth
0 task: blink-task
: blink ( task -- )
    activate
    begin ... pause again
    deactivate ;

multi
blink-task blink
```

`single` returns to one thread. `mutex:` / `wait` / `signal` are included.

### `network.fth`

Wi‑Fi and sockets. Helpers throw `EWIFI` / `ELWIP`.

```forth
wifi-init
"secret" "MySSID" wifi-connect
0 wifi-ip .ipv4 cr          \ 0 = STA, 1 = AP

4 3 0 WIFI_AUTH_WPA2_PSK "1234567890" "my-ap" wifi-softap
```

Sockets: `UDP` / `TCP`, `socket-new`, `socket-bind`, `socket-listen`, `socket-accept`, `socket-connect`, `socket-send`, `socket-recv`, `socket-close`. After `network.fth`, accept/recv loop with `pause` until data arrives.

Lower-level primitives: `wifi-set-mode`, `wifi-set-sta-config`, `wifi-set-ap-config`, `wifi-start`, `wifi-stop`, `wifi-sta-connect`, `wifi-sta-disconnect`, `get-host-by-name`, `>ipv4`, `ping`.

### `ringbuf.fth` and `mailbox.fth`

`ringbuf.fth` provides fixed-capacity circular buffers. Load it before
`mailbox.fth`, which builds cooperative-task mailboxes on top of ring buffers.

```forth
load: /f/ringbuf.fth
load: /f/mailbox.fth
```

### `ntp.fth`

```forth
-240 offset !     \ minutes from UTC, e.g. EDT
sync              \ 123/UDP time.nist.gov
time . cr         \ unix time plus offset
```

### `bt.fth`

Nordic UART Service on NimBLE.

```forth
"PunyForth" bt-start
```

Primitives: `bt-init`, `bt-set-name`, `bt-advertise`, `bt-stop-advertise`, `bt-connected`, `bt-available`, `bt-read`, `bt-write`.

Events on the shared queue: `EVT_BT_CONNECT` (140), `EVT_BT_DISCONNECT` (141), `EVT_BT_RX` (142).

Wi‑Fi and BLE can run together (ESP coexistence). Call `bt-init` before or after `wifi-init`.

Host console:

```bash
pip install --user bleak
python3 tools/bt_console.py
python3 tools/bt_console.py --name PunyForth
python3 tools/bt_console.py --address AA:BB:CC:DD:EE:FF
```

On-device echo: `examples/bt-echo.fth` (`bt-echo`, exit with Ctrl-D).

### `adc.fth`

Oneshot ADC with calibration. On ESP32-C3, ADC1 channels 0..4 map to GPIO0..GPIO4.

```forth
ADC_CH2 ADC_ATTEN_12DB adc-setup
adc@                               \ raw count 0..4095
adc-mv@                            \ millivolts
adc-mv@ .volts                     \ e.g. 1.234 V
```

Attenuation (input range):

| Constant            | Approx. range |
|---------------------|---------------|
| `ADC_ATTEN_0DB`     | 0..950 mV     |
| `ADC_ATTEN_2_5DB`   | 0..1250 mV    |
| `ADC_ATTEN_6DB`     | 0..1750 mV    |
| `ADC_ATTEN_12DB`    | 0..3300 mV    |

Primitives: `adc-init`, `adc-config`, `adc-read`, `adc-del`, `adc-cali-init`, `adc-raw>mv`, `adc-cali-del`. Example: `examples/adc-ex.fth`.

### `onewire.fth`

Dallas 1-Wire (`espressif/onewire_bus`, RMT) and DS18B20 helpers.

```forth
4 1w-open 1w-bus !          \ GPIO4 + 4.7 kΩ pull-up to 3V3
['] .rom 1w-each-rom cr
ds18b20-read .millic cr     \ 23.500 C
```

Power the sensor from 3V3; do not use parasite power. Primitives: `1w-init`, `1w-del`, `1w-reset`, `1w-write`, `1w-read`, `1w-search-begin`, `1w-search-next`, `1w-search-end`, `1w-crc8`. Example: `examples/ds18b20.fth`.

## GPIO, events, LEDs

Mode constants live in `core.fth`.

```forth
2 GPIO_MODE_OUTPUT gpio-mode
2 GPIO_HIGH gpio-write
2 gpio-read .
```

Interrupts post to the queue (`wait-event` / `next-event`):

| Code | Name | Source |
|------|------|--------|
| 100 | `EVT_GPIO` | `gpio-set-interrupt` |
| 110 | `EVT_BTN` | `btn-init` (short / long press) |
| 120 | `EVT_ROTARY` | `rotary-init` |
| 130 | `EVT_PING` | ICMP |
| 140–142 | BLE | connect / disconnect / RX |

WS2812:

```forth
2 1 led-strip-init          \ ( pin n -- strip )
dup 0 0x001000 led-strip-set-pixel
dup led-strip-clear
led-strip-del
```

A blink example is in `examples/blink.fth` (`start-blink`).

## Unit tests (`tests/`)

| File               | What it tests |
|--------------------|---------------|
| `core-tests.fth`   | Core Forth regression tests |
| `ringbuf-test.fth` | Ring-buffer operations and errors |

## Examples (`examples/`)

| File             | What it does |
|------------------|--------------|
| `adc-ex.fth`     | ADC readings and voltage helpers |
| `blink.fth`      | blink a WS2812 LED |
| `bt-echo.fth`    | BLE echo |
| `ds18b20.fth`    | DS18B20 temperature readings |
| `ping.fth`       | ICMP ping helper |
| `print-file.fth` | print a FAT file |
| `tcp-echo.fth`   | TCP echo server |
| `tcp-repl.fth`   | TCP Forth REPL server |

## VM resources

Set in `main/data.S`:

- dictionary heap: 64 KB
- data stack and return stack: 112 bytes each (~28 cells)
- input buffer: 128 bytes
- maximum word name length: 63

Background task stack sizes are `task-stack-size` / `task-rstack-size` in `tasks.fth` (also 112 by default).

## License

This project is licensed under the MIT License; see [LICENSE](./LICENSE).
ESP-IDF and Espressif components have their own licenses.
