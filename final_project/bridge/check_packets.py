#!/usr/bin/env python3
from pathlib import Path
import sys


NAMES = {
    0x01: "SET_MODE",
    0x02: "SET_COLOR",
    0x03: "SET_GAIN",
    0x04: "MAC_STEP",
    0x05: "CLEAR",
    0x06: "GET_STATUS",
    0x7F: "PING",
}


def crc8(data: bytes) -> int:
    crc = 0

    for value in data:
        crc ^= value

        for _ in range(8):
            crc = (
                ((crc << 1) ^ 0x07) & 0xFF
                if crc & 0x80
                else (crc << 1) & 0xFF
            )

    return crc


def main() -> int:
    if len(sys.argv) != 2:
        print(
            "uso: check_packets.py commands.bin",
            file=sys.stderr
        )
        return 2

    raw = Path(sys.argv[1]).read_bytes()

    if len(raw) == 0 or len(raw) % 10:
        print(
            f"FALHA: tamanho {len(raw)} nao e multiplo de 10",
            file=sys.stderr
        )
        return 1

    failed = 0

    for number in range(len(raw) // 10):
        packet = raw[number * 10:(number + 1) * 10]

        expected = crc8(packet[1:9])

        ok = (
            packet[0] == 0xA5
            and packet[1] == 1
            and packet[9] == expected
        )

        failed += not ok

        name = NAMES.get(
            packet[3],
            f"CMD_{packet[3]:02X}"
        )

        print(
            f"pacote {number:02d} "
            f"seq={packet[2]:02X} "
            f"cmd={name:<10} "
            f"len={packet[4]} "
            f"crc={packet[9]:02X} "
            f"{'PASS' if ok else 'FALHA'}"
        )

    print(
        f"resultado: "
        f"{len(raw) // 10 - failed} PASS, "
        f"{failed} FALHA"
    )

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())