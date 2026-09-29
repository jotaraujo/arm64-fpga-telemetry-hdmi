from pathlib import Path
import sys

def main() -> int:
  if len(sys.argv) != 3:
    print("uso: bin_to_hex.py entrada.bin saida.hex", file=sys.stderr)
    return 2

  source = Path(sys.argv[1])
  target = Path(sys.argv[2])
  target.parent.mkdir(parents=True, exist_ok=True)
  target.write_text("".join(f"{byte:02x}\n" for byte in source.read_bytes()), encoding="ascii")
  print(f"{source}: {source.stat().st_size} bytes -> {target}")
  return 0

if __name__ == "__main__":
  raise SystemExit(main())