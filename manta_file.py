import time
import struct 
from manta import Manta
m = Manta('finalproj.yaml') # create manta python instance using yaml

while True:
  a = m.lab8_io_core.gx.get() # Read gx
  b = m.lab8_io_core.gy.get() # Read gy
  c = m.lab8_io_core.gz.get() # Read gz

  print(f"gx: {a}, gy: {b}, gz: {c}")



