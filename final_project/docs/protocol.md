# Protocolo ARM64 -> FPGA
Pacote de comando: 10 bytes.
| Índice | Campo | Conteúdo |
|---:|---|---|
| 0 | SOF | `0xA5` |
| 1 | Versão | `0x01` |
| 2 | Sequência | Incrementa por comando |
| 3 | Comando | ID da operação |
| 4 | Length | 0 a 4 |
| 5-8 | Payload | 4 bytes; zeros quando não usados |
| 9 | CRC-8 | Polinômio `0x07` sobre bytes 1 a 8 |
Comandos: `01 SET_MODE`, `02 SET_COLOR`, `03 SET_GAIN`, `04 MAC_STEP`,
`05 CLEAR`, `06 GET_STATUS`, `7F PING`.
Resposta: 8 bytes iniciando em `0x5A`, com versão, sequência, status,
modo ativo, contador de erros (LSB/MSB) e CRC.
CRC-8: poly `0x07`, init `0x00`, sem reflexão, xorout `0x00`.