#!/usr/bin/env python3
"""Gera testes de corrupcao CRC-8 para a UART simulada do projeto.

Nao altera commands.hex nem random_packets.hex.
Execute na raiz de final_project: python3 bridge/gen_crc_stress.py
"""
from itertools import combinations
from pathlib import Path
import csv

SIM_DIR = Path(__file__).resolve().parents[1] / "fpga" / "sim"
SOF = 0xA5
VERSION = 0x01
CMD_PING = 0x7F
LEN_PING = 4
PAYLOAD_PING = 0x44332211


def crc8(message):
    """CRC-8 polinomio 0x07, init 0, sem reflexao, xorout 0."""
    crc = 0
    for byte in message:
        crc ^= byte
        for _ in range(8):
            crc = (((crc << 1) ^ 0x07) if crc & 0x80 else (crc << 1)) & 0xFF
    return crc


def pacote_valido(seq):
    body = [VERSION, seq, CMD_PING, LEN_PING, *PAYLOAD_PING.to_bytes(4, 'little')]
    return [SOF, *body, crc8(body)]


def inverter_bits(original, posicoes):
    pacote = original.copy()
    for byte_i, bit_i in posicoes:
        pacote[byte_i] ^= 1 << bit_i
    return pacote


def main():
    # 8 bytes protegidos (indices 1..8) + 1 byte de CRC (indice 9).
    # SOF (indice 0) fica de fora: nao e protegido pelo CRC.
    posicoes = [(byte_i, bit_i) for byte_i in range(1, 10) for bit_i in range(8)]
    assert len(posicoes) == 72
    # Vetor conhecido: SET_MODE(1), sequencia 1 => CRC 0x91.
    assert crc8(bytes.fromhex('01 01 01 01 01 00 00 00')) == 0x91

    casos = []
    def adicionar(nome, pacote, status, detalhes):
        casos.append((nome, pacote, status, detalhes))

    # Pacote que deve ser aceito primeiro.
    adicionar('VALIDO_INICIAL', pacote_valido(0), 0, 'PING seq=0')

    base = pacote_valido(1)
    assert len(base) == 10

    # Testes sistematicos, nao apenas sorteio: todas as posicoes de um bit.
    for p in posicoes:
        adicionar('1_BIT', inverter_bits(base, [p]), 1, str(p))

    # Todas as combinacoes possiveis de dois bits distintos.
    for p, q in combinations(posicoes, 2):
        adicionar('2_BITS', inverter_bits(base, [p, q]), 1, f'{p};{q}')

    # Um pacote valido no final demonstra recuperacao apos muitos erros.
    adicionar('VALIDO_FINAL', pacote_valido(2), 0, 'PING seq=2')

    assert len(casos) == 2630
    for i, (nome, pacote, status, detalhes) in enumerate(casos):
        encontrado = crc8(pacote[1:9])
        if (encontrado == pacote[9]) != (status == 0):
            raise AssertionError(
                f'Caso {i}: expectativa de CRC incorreta! '
                f'nome={nome}, calculado={encontrado:02X}, recebido={pacote[9]:02X}'
            )

    SIM_DIR.mkdir(parents=True, exist_ok=True)
    (SIM_DIR / 'crc_stress_packets.hex').write_text(
        ''.join(f'{byte:02x}\n' for _, pacote, _, _ in casos for byte in pacote),
        encoding='ascii',
    )
    (SIM_DIR / 'crc_stress_expected.hex').write_text(
        ''.join(f'{status:02x}\n' for _, _, status, _ in casos),
        encoding='ascii',
    )
    with (SIM_DIR / 'crc_stress_manifest.csv').open('w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['caso', 'categoria', 'posicoes_modificadas', 'pacote_hex', 'status_esperado'])
        for i, (nome, pacote, status, detalhes) in enumerate(casos):
            writer.writerow([i, nome, detalhes, ' '.join(f'{x:02X}' for x in pacote), status])

    print('Gerador CRC: 2 pacotes validos + 72 com 1 bit trocado + 2556 com 2 bits trocados')
    print('Total: 2630 casos; 2628 erros de CRC esperados')
    print(f'Arquivos criados em: {SIM_DIR}')
    print('Atenção: o SOF nao é protegido pelo CRC e nao está nestes casos.')


if __name__ == '__main__':
    main()
