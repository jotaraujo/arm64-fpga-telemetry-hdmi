
from pathlib import Path
import random

SEED = 12345
TOTAL = 1000
rng = random.Random(SEED)

OUT = Path(__file__).resolve().parents[1] / "fpga" / "sim"

COMMAND_LENGTHS = {
    0x01: 1,  # SET_MODE
    0x02: 3,  # SET_COLOR
    0x03: 2,  # SET_GAIN
    0x04: 4,  # MAC_STEP
    0x05: 0,  # CLEAR
    0x06: 0,  # GET_STATUS
    0x7F: 4,  # PING
}

SCENARIOS = [
    "VALID",
    "BAD_CRC",
    "BAD_CMD",
    "BAD_LEN",
    "BAD_VERSION",
    "DUP_SEQ",
]


def crc8(data):
    crc = 0

    for byte in data:
        crc ^= byte

        for _ in range(8):
            if crc & 0x80:
                crc = ((crc << 1) ^ 0x07) & 0xFF
            else:
                crc = (crc << 1) & 0xFF

    return crc


def create_packet(seq, cmd, length, payload, version=1):
    body = [
        version,
        seq,
        cmd,
        length,
        *payload.to_bytes(4, "little"),
    ]

    return [0xA5, *body, crc8(body)]


def random_command():
    cmd = rng.choice(list(COMMAND_LENGTHS))
    length = COMMAND_LENGTHS[cmd]

    if cmd == 0x01:
        payload = rng.randrange(4)
    elif cmd == 0x02:
        payload = rng.getrandbits(24)
    elif cmd == 0x03:
        payload = rng.getrandbits(16)
    elif cmd in (0x05, 0x06):
        payload = 0
    else:
        payload = rng.getrandbits(32)

    return cmd, length, payload


def main():
    packets = []
    expected = []
    manifest = []

    # Histórico das sequências aceitas.
    last_accepted = None
    next_seq = 0

    for i in range(TOTAL):
        # Alterna categorias para garantir que todas sejam testadas.
        scenario = SCENARIOS[i % len(SCENARIOS)]

        # A primeira execução precisa aceitar um pacote,
        # para depois existir uma sequência duplicável.
        if i == 0:
            scenario = "VALID"

        if scenario == "DUP_SEQ":
            seq = last_accepted
        else:
            seq = next_seq
            next_seq = (next_seq + 1) & 0xFF

            if seq == last_accepted:
                seq = next_seq
                next_seq = (next_seq + 1) & 0xFF

        cmd, length, payload = random_command()
        version = 1
        status = 0

        if scenario == "BAD_CMD":
            cmd = 0x99
            status = 3

        elif scenario == "BAD_LEN":
            length = rng.randint(5, 255)
            status = 4

        elif scenario == "BAD_VERSION":
            version = 2
            status = 3

        elif scenario == "BAD_CRC":
            status = 1

        elif scenario == "DUP_SEQ":
            status = 2

        packet = create_packet(
            seq, cmd, length, payload, version
        )

        if scenario == "BAD_CRC":
            packet[9] ^= 0x01

        if scenario == "VALID":
            last_accepted = seq

        packets.extend(packet)
        expected.append(status)

        manifest.append(
            f"{i},{scenario},{seq},{cmd:02X},"
            f"{payload:08X},{status}"
        )

    OUT.mkdir(parents=True, exist_ok=True)

    (OUT / "random_packets.hex").write_text(
        "\n".join(f"{b:02x}" for b in packets) + "\n"
    )

    (OUT / "random_expected.hex").write_text(
        "\n".join(f"{s:02x}" for s in expected) + "\n"
    )

    (OUT / "random_manifest.csv").write_text(
        "case,scenario,seq,cmd,payload,expected\n"
        + "\n".join(manifest) + "\n"
    )

    print(f"Seed: {SEED}")
    print(f"Pacotes gerados: {TOTAL}")
    print(f"Bytes gerados: {len(packets)}")
    print(f"Arquivos salvos em: {OUT}")


if __name__ == "__main__":
    main()
