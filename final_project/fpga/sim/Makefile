IVERILOG ?= iverilog
VVP ?= vvp
FLAGS := -g2012 -Wall
.RECIPEPREFIX := >

RTL := \
	../rtl/control/uart_rx.v \
	../rtl/control/uart_tx.v \
	../rtl/control/packet_parser.v \
	../rtl/control/response_builder.v \
	../rtl/control/command_executor.v \
	../rtl/dsp/mac_unit.v \
	../rtl/io/led_status.v \
	../rtl/protocol_system.v

.PHONY: all mac status video protocol clean
all: mac status video protocol

build:
>mkdir -p build

.PHONY: all mac status video protocol random clean
random: build
>@test -f random_packets.hex && test -f random_expected.hex || (echo "Gere os pacotes com Python primeiro"; exit 1)
>$(IVERILOG) $(FLAGS) -o build/tb_random_protocol.vvp $(RTL) tb_random_protocol.v
>$(VVP) build/tb_random_protocol.vvp

.PHONY: all mac status video protocol random crc-stress clean
crc-stress: build
>@test -f crc_stress_packets.hex && test -f crc_stress_expected.hex || (echo "Gere os testes CRC com Python primeiro"; exit 1)
>$(IVERILOG) $(FLAGS) -o build/tb_crc_stress.vvp $(RTL) tb_crc_stress.v
>$(VVP) build/tb_crc_stress.vvp

uart-stress: build
>$(IVERILOG) $(FLAGS) -o build/tb_uart_stress.vvp ../rtl/control/uart_rx.v tb_uart_stress.v
>$(VVP) build/tb_uart_stress.vvp

packet-recovery: build
>$(IVERILOG) $(FLAGS) -o build/tb_packet_recovery.vvp $(RTL) tb_packet_recovery.v
>$(VVP) build/tb_packet_recovery.vvp

mac: build
>$(IVERILOG) $(FLAGS) -o build/tb_mac_unit.vvp ../rtl/dsp/mac_unit.v tb_mac_unit.v
>$(VVP) build/tb_mac_unit.vvp

status: build
>$(IVERILOG) $(FLAGS) -o build/tb_led_status.vvp ../rtl/io/led_status.v tb_led_status.v
>$(VVP) build/tb_led_status.vvp

video: build
>$(IVERILOG) $(FLAGS) -o build/tb_pattern_stream.vvp ../rtl/video/pattern_stream.v tb_pattern_stream.v
>$(VVP) build/tb_pattern_stream.vvp

protocol: build
>@test -f commands.hex || (echo "FALHA: execute make -C ../../arm64 hex primeiro"; exit 1)
>$(IVERILOG) $(FLAGS) -o build/tb_arm_fpga_protocol.vvp $(RTL) tb_arm_fpga_protocol.v
>$(VVP) build/tb_arm_fpga_protocol.vvp

clean:
>rm -rf build
