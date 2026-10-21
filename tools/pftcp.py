#!/usr/bin/env python3
import argparse
import asyncio
import os
import sys
from pathlib import Path

from prompt_toolkit import PromptSession
from prompt_toolkit.application import run_in_terminal
from prompt_toolkit.history import FileHistory
from prompt_toolkit.key_binding import KeyBindings


async def run(host: str, port: int) -> None:
    reader, writer = await asyncio.open_connection(host, port)
    receiver = None
    try:
        initial = await reader.read(4096)
        if not initial:
            raise ConnectionError("TCP REPL closed the connection")
        print(initial.decode("utf-8", errors="replace"), end="", flush=True)

        histfile = os.path.join(os.path.expanduser("~"), ".pf_history")
        session = PromptSession(history=FileHistory(histfile))
        mode = {"file": False, "exit": False}
        bindings = KeyBindings()

        @bindings.add("c-a")
        def select_file(event):
            mode["file"] = True
            mode["exit"] = False

        @bindings.add("c-q")
        @bindings.add("c-e")
        def request_exit(event):
            mode["exit"] = True
            mode["file"] = False

        @bindings.add("escape")
        def cancel_exit(event):
            mode["exit"] = False

        def prompt_message():
            if mode["file"]:
                return "File to send> "
            if mode["exit"]:
                return "Press Enter to disconnect (Esc cancels)> "
            return ""

        async def receive_output() -> None:
            while data := await reader.read(4096):
                text = data.decode("utf-8", errors="replace")
                await run_in_terminal(lambda: print(text, end="", flush=True))

        receiver = asyncio.create_task(receive_output())
        while True:
            input_task = asyncio.create_task(
                session.prompt_async(message=prompt_message, key_bindings=bindings)
            )
            done, _ = await asyncio.wait(
                (input_task, receiver), return_when=asyncio.FIRST_COMPLETED
            )
            if receiver in done:
                input_task.cancel()
                try:
                    await input_task
                except asyncio.CancelledError:
                    pass
                await receiver
                print("TCP REPL disconnected.")
                return

            line = await input_task
            if mode["exit"]:
                break
            if mode["file"]:
                mode["file"] = False
                path = Path(line)
                try:
                    content = path.read_bytes()
                except OSError as error:
                    print(f"pftcp: cannot read {path}: {error}", file=sys.stderr)
                    continue

                lines = (
                    content.replace(b"\r\n", b"\n")
                    .replace(b"\r", b"\n")
                    .split(b"\n")
                )
                if any(len(file_line) > 125 for file_line in lines):
                    print(
                        f"pftcp: {path} contains a line longer than the TCP REPL's "
                        "125-byte limit",
                        file=sys.stderr,
                    )
                    continue
                if content and not content.endswith((b"\n", b"\r")):
                    content += b"\n"
                writer.write(content)
                await writer.drain()
                continue

            command = line.encode("utf-8")
            if len(command) > 125:
                print("pftcp: command exceeds the TCP REPL's 125-byte line limit")
                continue
            writer.write(command + b"\n")
            await writer.drain()
    finally:
        try:
            if receiver is not None:
                receiver.cancel()
                try:
                    await receiver
                except asyncio.CancelledError:
                    pass
        finally:
            writer.close()
            await writer.wait_closed()


def main() -> int:
    parser = argparse.ArgumentParser(description="TCP terminal for a Punyforth REPL")
    parser.add_argument("host", help="device IP address or hostname")
    parser.add_argument("--port", type=int, default=1983, help="TCP port (default: 1983)")
    args = parser.parse_args()

    try:
        asyncio.run(run(args.host, args.port))
    except OSError as error:
        print(f"pftcp: {error}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        return 130
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
