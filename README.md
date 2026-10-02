# Sistema Embarcado ARM64–FPGA com Processamento MAC, Telemetria e HDMI


Repositório acadêmico desenvolvido ao longo do Projeto de Bloco de **Sistemas Digitais Embarcados**, reunindo a evolução de cinco TPs e um projeto final integrado envolvendo:

- **Assembly AArch64 / ARM64**;
- **QEMU** e depuração de software embarcado;
- **Verilog**;
- **FPGA Sipeed Tang Nano 4K**;
- simulação com **Icarus Verilog** e **GTKWave**;
- síntese, Place & Route e programação com **Gowin EDA**;
- máquinas de estados, sincronização e debounce;
- processamento **MAC (Multiply-Accumulate)**;
- **DSP** e **BSRAM/BRAM**;
- ponto fixo **Q8.8**;
- protocolos, checksum/CRC e telemetria;
- geração de vídeo;
- saída **HDMI** no projeto final.

O repositório preserva a evolução do projeto do **TP1 ao TP5** e acrescenta `final_project/`, que consolida os conceitos anteriores em um único protótipo verificável.

---

## 1. Visão geral

A ideia central desenvolvida ao longo do bloco foi estudar como um processador ARM e uma FPGA podem cooperar em um sistema embarcado.

A arquitetura foi evoluindo progressivamente:

```text
TP1
Arquitetura ARM + FPGA e proposta de vídeo
    ↓
TP2
Sincronismo de vídeo, pixels, testbenches e framebuffer
    ↓
TP3
FSM, sincronização de entradas, debounce, GPIO e automação de build
    ↓
TP4
MAC, DSP, BSRAM, Q8.8, rotinas numéricas e telemetria
    ↓
TP5
Biblioteca Assembly, protocolo, handshaking e integração parcial
    ↓
PROJETO FINAL
Co-simulação ARM64 → FPGA + datapath físico na Tang Nano 4K + HDMI
```

O resultado final não substitui os TPs anteriores: ele **consolida e corrige** as decisões técnicas tomadas ao longo deles.

---

## 2. Hardware e ambientes

### FPGA

- **Sipeed Tang Nano 4K**
- FPGA Gowin da família **GW1NSR**
- Gowin EDA / FPGA Designer
- Gowin Programmer
- HDMI para monitor
- botões e LED onboard

### ARM64

A proposta inicial utilizava um **Raspberry Pi Zero 2W** como host ARM Cortex-A53.

Durante o desenvolvimento dos TPs mais avançados, o hardware físico Raspberry Pi não estava disponível. Por isso, a frente ARM64 passou a ser validada por:

- `qemu-aarch64`;
- GDB remoto;
- `objdump`;
- toolchain GNU AArch64.

No projeto final, essa adaptação foi mantida e formalizada.

> **Importante:** no projeto final não existe um enlace UART físico em tempo real entre QEMU/PC e a Tang Nano. A integração ARM64–FPGA é comprovada por **co-simulação**, enquanto a Tang Nano física valida o datapath FPGA, MAC, memória, botões, LED e HDMI.

---

# 3. Evolução do projeto

## TP1 — Arquitetura inicial ARM → FPGA → vídeo

O TP1 definiu a visão inicial do sistema.

A proposta era construir um **Controlador VGA com Framebuffer ARM→FPGA**, no qual:

- o Raspberry Pi Zero 2W atuaria como host ARM64;
- o ARM geraria conteúdo de imagem;
- os dados seriam enviados ao FPGA por SPI;
- a Tang Nano armazenaria pixels em BRAM;
- o FPGA geraria sincronismo VGA 640×480 @ 60 Hz.

Fluxo conceitual planejado:

```text
ARM Cortex-A53
    ↓
SPI
    ↓
FPGA
    ↓
BRAM / framebuffer
    ↓
VGA sync + RGB
    ↓
Monitor
```

### Principais conceitos estudados

- divisão de responsabilidades entre CPU e FPGA;
- Assembly AArch64;
- memória de vídeo;
- BRAM;
- SPI;
- sincronismo VGA;
- resolução 640×480 @ 60 Hz;
- Icarus Verilog;
- GTKWave;
- síntese no Gowin.

### Papel do TP1 no projeto final

O TP1 forneceu a **arquitetura-base**: software ARM como produtor de dados/comandos e FPGA como hardware especializado.

A ideia de framebuffer completo, entretanto, foi posteriormente revisada devido às limitações de memória interna da Tang Nano 4K.

---

## TP2 — Sincronismo, geração de pixels e simulação

O TP2 transformou a arquitetura do TP1 em implementação técnica mais concreta.

No lado FPGA foram trabalhados módulos como:

- `vga_sync.v`;
- `pattern_generator.v`;
- `tb_vga_system.v`.

Foram estudados:

- contadores horizontal e vertical;
- HSYNC e VSYNC;
- coordenadas de pixel;
- região visível;
- geração de padrões;
- simulação temporal;
- constraints de pinos;
- síntese física.

No lado ARM64, o programa evoluiu para rotinas estruturadas de preenchimento de buffer, utilizando:

- loops;
- condicionais;
- cálculo de endereço;
- gravação byte a byte;
- chamadas de sistema.

### Fluxo estudado

```text
ARM
 ├─ calcula endereço
 ├─ escolhe cor
 └─ grava no buffer
       ↓
interface SPI planejada
       ↓
FPGA
 ├─ sincronismo
 ├─ leitura de pixel
 └─ geração de vídeo
```

### Aprendizado importante

O TP2 ajudou a separar duas ideias:

1. **gerar coordenadas e padrões de vídeo**;
2. possuir um pipeline físico completo de saída HDMI/VGA.

No projeto final, essa distinção se tornou importante: a geração visual foi preservada, mas a saída passou a utilizar o pipeline HDMI oficial da Sipeed.

---

## TP3 — FSM, entradas físicas e controle ARM64

O TP3 introduziu uma camada de controle mais sofisticada.

### FPGA

Foi criada uma **FSM receptora de comandos**, com estados para:

- espera;
- sincronização;
- validação;
- execução;
- erro;
- espera de liberação.

Também foram trabalhados:

- sincronizador de dois flip-flops;
- debounce;
- botões físicos;
- LED onboard;
- handshake;
- validação física na Tang Nano 4K.

### ARM64

A frente Assembly passou a incluir:

- loops;
- condicionais múltiplas;
- tabela de salto;
- mini-parser de comandos;
- mapeamento conceitual de GPIO;
- acesso com `LDR` e `STR`;
- Makefile modular;
- compilação incremental;
- execução e depuração no QEMU;
- análise com `objdump`.

A estrutura Assembly do TP3 separou fontes e artefatos de build, automatizando alvos como:

```text
make all
make clean
make run
make debug
make disasm
```

### Papel do TP3 no projeto final

O TP3 forneceu conceitos fundamentais usados diretamente no projeto final:

- sincronização de entradas;
- debounce;
- FSM;
- executor de comandos;
- tratamento de botões;
- automação de build.

---

## TP4 — MAC, DSP, BRAM e rotinas numéricas

O TP4 adicionou o núcleo de processamento numérico do projeto.

### FPGA

Foi desenvolvida uma unidade **MAC — Multiply-Accumulate**.

Operação conceitual:

```text
acc_novo = acc_anterior + (A × B)
```

Foram estudados:

- multiplicação 16×16;
- acumulador;
- overflow;
- saturação;
- BRAM/BSRAM;
- uso de blocos DSP;
- controlador para o datapath;
- telemetria.

A síntese no Gowin permitiu verificar o uso efetivo de:

- memória em bloco;
- DSP dedicado.

### ARM64

O TP4 expandiu o Assembly para rotinas numéricas mais avançadas:

- aritmética multi-palavra;
- conversões inteiro ↔ ponto flutuante;
- lookup tables;
- operações bitwise;
- NEON SIMD;
- comunicação simulada;
- checksum;
- registro de telemetria.

### Restrição de ambiente

A frente ARM64 foi validada com QEMU, GDB e objdump.

A frente FPGA continuou sendo sintetizada e testada fisicamente na Tang Nano 4K.

### Papel do TP4 no projeto final

O TP4 forneceu o núcleo de:

```text
MAC
 +
DSP
 +
memória de telemetria
 +
detecção de overflow
```

que aparece no modo de telemetria HDMI do projeto final.

---

## TP5 — Organização do software e integração parcial

O TP5 consolidou as duas frentes do projeto antes da integração final.

### FPGA

A unidade MAC foi revisada e recebeu um testbench mais completo, cobrindo:

- zero;
- produto Q8.8;
- saturação positiva;
- freeze de saída;
- retomada após `clear`;
- saturação negativa.

O projeto físico integrava:

- sincronização;
- debounce;
- controle;
- BRAM;
- MAC;
- DSP;
- botões;
- LED.

### ARM64

O software foi reorganizado em módulos temáticos:

```text
src/
├── arith/
├── io/
├── parsing/
├── utils/
├── link/
└── neon/
```

Entre as rotinas estavam:

- aritmética de 128 bits;
- conversões numéricas;
- MAC em software;
- syscalls;
- mapeamento GPIO;
- parser;
- `itoa` / `atoi`;
- operações bitwise;
- lookup;
- buffers;
- macros;
- protocolo;
- benchmarks;
- NEON inteiro e ponto flutuante.

Os módulos foram compilados em uma biblioteca estática:

```text
build/libtp5.a
```

### Protocolo

O TP5 evoluiu a ideia de comunicação com:

- handshaking;
- checksum;
- payload;
- resposta;
- telemetria.

A integração física ARM–FPGA completa ainda permanecia pendente pela ausência do Raspberry Pi físico.

### Papel do TP5 no projeto final

O TP5 forneceu:

- organização modular do Assembly;
- conceitos de protocolo;
- parser;
- comunicação;
- telemetria;
- testes de borda;
- integração parcial entre as frentes.

---

# 4. Projeto final — consolidação dos TPs

O diretório `final_project/` reúne os conceitos anteriores em uma arquitetura única.

O objetivo final é demonstrar um sistema embarcado com:

```text
entrada
  ↓
protocolo / controle
  ↓
processamento MAC
  ↓
memória
  ↓
telemetria / estado
  ↓
HDMI + LED
```

A validação foi dividida em duas frentes.

---

## 4.1 Co-simulação ARM64 → FPGA

O programa AArch64 executado no QEMU produz pacotes reais de 10 bytes.

Fluxo:

```text
main.s / packet.s
      ↓
qemu-aarch64
      ↓
commands.bin
      ↓
bin_to_hex.py
      ↓
commands.hex
      ↓
UART simulada
      ↓
packet_parser
      ↓
command_executor
      ↓
ACK / erro / estado
```

O testbench envia os bytes **bit a bit**, simulando o transporte UART.

São validados:

- 8 comandos corretos;
- CRC incorreto;
- sequência duplicada;
- ACK/NACK;
- contador de erros;
- atualização de registradores;
- processamento MAC.

Resultado esperado:

```text
resultado: 8 PASS, 0 FALHA

PASS tb_mac_unit
PASS tb_led_status
PASS tb_pattern_stream: active_mode 00/01/10/11 visivel no HDMI
PASS integracao ARM64 FPGA: 8 ACK, CRC e duplicata detectados
```

---

## 4.2 Implementação física na Tang Nano 4K

Na placa física, os comandos entram pelos botões onboard.

Fluxo:

```text
KEY1 / KEY2
    ↓
sync2ff
    ↓
debounce_pulse
    ↓
button_commands
    ↓
command_executor
    ├──────────────┐
    ↓              ↓
 active_mode      MAC
    ↓              ↓
 HDMI        telemetry_bram
                   ↓
                  HDMI
```

O LED onboard é usado para status.

---

# 5. Arquitetura do projeto final

## ARM64

Responsável por:

- criar os comandos;
- preencher payload;
- gerar sequência;
- calcular CRC;
- produzir `commands.bin`.

## Bridge

Responsável por:

- converter binário para hexadecimal;
- verificar tamanho e integridade dos pacotes.

## Protocolo FPGA simulado

Inclui:

- UART RX;
- parser de pacotes;
- validação de CRC;
- detecção de sequência duplicada;
- executor;
- builder de resposta;
- UART TX.

## Datapath físico

Inclui:

- sincronização;
- debounce;
- botões;
- executor de comandos;
- MAC Q8.8;
- memória de telemetria;
- LED de status;
- HDMI.

---

# 6. Protocolo final

Cada comando possui 10 bytes:

| Byte | Campo |
|---:|---|
| 0 | SOF `0xA5` |
| 1 | versão `0x01` |
| 2 | sequência |
| 3 | ID do comando |
| 4 | tamanho |
| 5–8 | payload |
| 9 | CRC-8 |

CRC:

```text
poly   = 0x07
init   = 0x00
refin  = false
refout = false
xorout = 0x00
```

Comandos principais:

| ID | Comando |
|---:|---|
| `0x01` | `SET_MODE` |
| `0x02` | `SET_COLOR` |
| `0x03` | `SET_GAIN` |
| `0x04` | `MAC_STEP` |
| `0x05` | `CLEAR` |
| `0x06` | `GET_STATUS` |
| `0x7F` | `PING` |

Status usados na integração:

| Status | Resultado |
|---:|---|
| `0x00` | ACK |
| `0x01` | CRC inválido |
| `0x02` | sequência duplicada |

---

# 7. MAC e ponto fixo Q8.8

O MAC executa:

```text
acumulador = acumulador + A × B
```

Os operandos utilizam ponto fixo **Q8.8**.

Exemplos:

```text
0x0100 = 1,0
0x0080 = 0,5
0xFF00 = -1,0
```

O design final utiliza:

- operandos de 16 bits;
- acumulador de 32 bits;
- saturação;
- detecção de overflow;
- conversão de resultado para Q8.8;
- DSP dedicado na FPGA.

---

# 8. Memória e mudança em relação ao framebuffer

A arquitetura inicial previa framebuffer 640×480.

Um quadro de 640×480 com apenas um byte por pixel exigiria:

```text
640 × 480 = 307200 bytes
```

Isso ultrapassa a capacidade de memória em bloco disponível para o uso pretendido na Tang Nano 4K.

Por isso, o projeto final mudou a estratégia:

```text
antes:
BRAM → framebuffer completo

final:
pixels → gerados proceduralmente
BSRAM → telemetria MAC
```

Essa mudança permitiu manter a geração de vídeo e usar a memória interna em uma função que realmente cabe no dispositivo.

---

# 9. HDMI no projeto final

A saída final utiliza o pipeline HDMI oficial da Sipeed, preservando os módulos SVO/TMDS e os IPs de clock.

`active_mode` possui dois bits:

| Modo | Resultado |
|---|---|
| `00` | barras de cores |
| `01` | xadrez |
| `10` | gradiente RGB |
| `11` | telemetria do MAC |

Dois indicadores no canto superior direito mostram os bits de `active_mode`.

O HDMI é usado como **interface de observação do estado interno**, não apenas como saída estética.

---

# 10. LED onboard e botões

## LED

O LED onboard sinaliza:

| Evento | Comportamento |
|---|---|
| comando aceito | 1 piscada |
| erro de protocolo/comando | 2 piscadas |
| erro grave / overflow | piscada rápida contínua |

## KEY1

```text
SET_MODE
```

Percorre:

```text
00 → 01 → 10 → 11 → 00
```

## KEY2

```text
MAC_STEP
```

Executa nova operação MAC.

## KEY1 + KEY2

```text
CLEAR
```

Limpa MAC, telemetria e alertas.

---

# 11. Estrutura geral do repositório

Os TPs anteriores são preservados como histórico da evolução do projeto.

A organização conceitual é:

```text
repositório/
├── TP1 / artefatos do TP1
├── TP2 / artefatos do TP2
├── TP3 / artefatos do TP3
├── TP4 / artefatos do TP4
├── TP5 / artefatos do TP5
│
└── final_project/
    ├── README.md
    ├── Makefile
    ├── arm64/
    ├── bridge/
    ├── docs/
    ├── evidence/
    └── fpga/
```

Os nomes e a divisão interna dos TPs refletem a organização usada em cada entrega. Por exemplo, no TP2 os artefatos foram separados em diretórios de Verilog, Assembly e documentação.

A pasta `final_project/` é a versão consolidada e reproduzível.

---

# 12. Estrutura de `final_project/`

```text
final_project/
├── README.md
├── Makefile
│
├── arm64/
│   ├── Makefile
│   ├── src/
│   │   ├── main.s
│   │   ├── packet.s
│   │   └── syscalls.s
│   └── build/
│
├── bridge/
│   ├── bin_to_hex.py
│   └── check_packets.py
│
├── docs/
│   └── protocol.md
│
├── evidence/
│   ├── waveforms/
│   ├── synthesis/
│   ├── hardware/
│   └── logs/
│
└── fpga/
    ├── bringup/
    ├── constraints/
    ├── rtl/
    │   ├── common/
    │   ├── control/
    │   ├── dsp/
    │   ├── io/
    │   ├── memory/
    │   └── video/
    ├── sim/
    ├── third_party/
    ├── gowin/
    └── release/
```

---

# 13. Dependências para o projeto final

No Ubuntu/WSL:

```bash
sudo apt update
sudo apt install -y \
  make \
  binutils-aarch64-linux-gnu \
  qemu-user \
  python3 \
  iverilog \
  gtkwave \
  git
```

Verifique:

```bash
aarch64-linux-gnu-as --version
qemu-aarch64 --version
python3 --version
iverilog -V
gtkwave --version
make --version
```

No Windows:

- Gowin EDA / FPGA Designer;
- Gowin Programmer.

---

# 14. Executando o projeto final

Entre em:

```bash
cd final_project
```

Limpe os artefatos:

```bash
make clean
```

Execute todo o fluxo de software e simulação:

```bash
make all
```

O resultado correto deve incluir:

```text
resultado: 8 PASS, 0 FALHA
PASS tb_mac_unit
PASS tb_led_status
PASS tb_pattern_stream: active_mode 00/01/10/11 visivel no HDMI
PASS integracao ARM64 FPGA: 8 ACK, CRC e duplicata detectados
```

---

# 15. Executando somente o ARM64

```bash
make -C arm64 check
```

Confira:

```bash
wc -c arm64/build/commands.bin
wc -l fpga/sim/commands.hex
```

Esperado:

```text
80 bytes
80 linhas
```

---

# 16. Executando somente as simulações FPGA

```bash
make -C fpga/sim all
```

Waveform da integração:

```bash
gtkwave fpga/sim/build/tb_arm_fpga_protocol.vcd
```

Waveform do MAC:

```bash
gtkwave fpga/sim/build/tb_mac_unit.vcd
```

Waveform do LED:

```bash
gtkwave fpga/sim/build/tb_led_status.vcd
```

---

# 17. Projeto físico no Gowin

Abra:

```text
final_project/fpga/gowin/final_project.gprj
```

Dispositivo:

```text
GW1NSR-LV4CQN48PC6/I5
```

Top final:

```text
top_final
```

Constraints:

```text
final.cst
final.sdc
```

Fluxo:

```text
Synthesize
    ↓
Place & Route
    ↓
Timing Analysis
    ↓
Programmer
```

A base HDMI oficial da Sipeed deve permanecer preservada.

---

# 18. Recursos verificados no projeto final

A implementação final foi projetada para utilizar:

- DSP `MULTADDALU18X18` ou equivalente;
- BSRAM;
- Gowin PLL;
- CLKDIV;
- OSER10;
- buffers diferenciais HDMI.

A análise de timing deve ser feita após Place & Route.

---

# 19. Evidências

As evidências do projeto final estão organizadas em:

```text
final_project/evidence/
```

Elas incluem:

- execução ARM64/QEMU;
- pacotes;
- testbenches;
- waveforms;
- CRC inválido;
- sequência duplicada;
- MAC;
- LED;
- síntese;
- utilização de recursos;
- timing;
- pinagem;
- Programmer;
- fotos dos modos HDMI;
- telemetria física.

---

# 20. Principais mudanças ao longo do projeto

| Tema | Ideia inicial | Solução final |
|---|---|---|
| ARM | Raspberry Pi físico | QEMU para validação ARM64 |
| Comunicação | SPI planejado | protocolo validado por UART em co-simulação |
| Vídeo | VGA | HDMI |
| Memória de vídeo | framebuffer completo | pixels procedurais |
| BRAM | framebuffer | telemetria |
| Controle | módulos isolados | executor de comandos |
| FPGA | exercícios separados | `top_final` integrado |
| Status | LED simples | LED onboard com padrões |
| Testes | validações individuais | fluxo automatizado `make all` |

---

# 21. Limitações técnicas

Este repositório documenta explicitamente as limitações do protótipo.

### ARM64 físico

O Raspberry Pi Zero 2W físico não esteve disponível nas etapas finais.

Portanto, a execução ARM64 foi validada em QEMU.

### Comunicação ARM → FPGA

O projeto final **não possui transporte elétrico ao vivo** entre QEMU e Tang Nano.

A integração é:

```text
ARM64 real executado no QEMU
        ↓
bytes reais
        ↓
UART simulada
        ↓
lógica FPGA
```

A Tang Nano física é exercitada pelos botões locais.

### Framebuffer

O projeto final não armazena uma imagem completa em BRAM.

Os pixels são calculados em tempo real.

---

# 22. O que o projeto final realmente demonstra

O projeto não é apenas um gerador de telas.

Ele demonstra o fluxo:

```text
comando
   ↓
validação
   ↓
execução
   ↓
processamento MAC
   ↓
armazenamento
   ↓
telemetria
   ↓
visualização
```

O HDMI funciona como painel de observação do sistema.

---

# 23. Tecnologias e conceitos estudados

### FPGA / Verilog

- RTL;
- módulos;
- top-level;
- FSM;
- lógica combinacional e sequencial;
- clock;
- reset;
- sincronizadores;
- debounce;
- testbenches;
- timing;
- constraints;
- síntese;
- Place & Route.

### Processamento

- MAC;
- DSP;
- BRAM/BSRAM;
- overflow;
- saturação;
- Q8.8;
- telemetria.

### Vídeo

- VGA;
- HSYNC;
- VSYNC;
- pixels;
- framebuffer;
- geração procedural;
- HDMI;
- TMDS;
- serialização.

### ARM64

- Assembly AArch64;
- registradores;
- loops;
- condicionais;
- jump tables;
- parsing;
- syscalls;
- GPIO;
- macros;
- biblioteca estática;
- multiword;
- bitwise;
- NEON SIMD.

### Comunicação

- SPI;
- UART;
- pacotes;
- payload;
- sequência;
- handshake;
- checksum;
- CRC;
- ACK/NACK.

### Ferramentas

- GNU AArch64 toolchain;
- QEMU;
- GDB;
- objdump;
- Make;
- Python;
- Icarus Verilog;
- GTKWave;
- Gowin EDA;
- Gowin Programmer.

---

# 24. Linha do tempo resumida

```text
TP1
│ Arquitetura ARM + FPGA
│ Vídeo, framebuffer e SPI
│
TP2
│ Sincronismo e geração de pixels
│ Testbench e Assembly de framebuffer
│
TP3
│ FSM
│ Debounce e sincronização
│ Parser ARM e GPIO
│
TP4
│ MAC
│ DSP + BRAM
│ Q8.8
│ NEON e telemetria
│
TP5
│ Biblioteca Assembly
│ Handshake
│ Checksum
│ Integração parcial
│
▼
PROJETO FINAL
  CRC-8
  UART simulada
  Co-simulação
  MAC + BSRAM
  HDMI
  LED onboard
  Tang Nano 4K
```

---

# 25. Resultado final

O repositório termina com um protótipo no qual:

- o ARM64 gera comandos estruturados;
- esses comandos são usados em uma co-simulação bit a bit;
- o parser FPGA detecta comandos válidos, CRC incorreto e duplicatas;
- o executor altera o estado do sistema;
- a unidade MAC processa dados Q8.8;
- a BSRAM armazena telemetria;
- o HDMI apresenta quatro modos;
- o LED onboard apresenta status;
- o design é sintetizado e programado na Tang Nano 4K.

---

# 26. Autor

**João Paulo Fonseca de Araújo**  
Engenharia da Computação — Instituto Infnet  
Projeto de Bloco: Sistemas Digitais Embarcados  
2026

---

## Resumo em uma frase

> Este repositório documenta a evolução, do TP1 ao projeto final, de uma arquitetura ARM64–FPGA que começou como um controlador de vídeo com framebuffer e evoluiu para um sistema embarcado integrado com protocolo validado por co-simulação, processamento MAC em hardware, telemetria em BSRAM e visualização HDMI na Tang Nano 4K.
