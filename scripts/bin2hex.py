#!/usr/bin/env python3
from pathlib import Path
import sys

data=Path(sys.argv[1]).read_bytes()
data+=bytes((-len(data))%4)
Path(sys.argv[2]).write_text("".join(f"{int.from_bytes(data[i:i+4],'little'):08x}\n" for i in range(0,len(data),4)))
