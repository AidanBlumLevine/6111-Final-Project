import time
import struct 
from pandas import DataFrame
from manta import Manta
m = Manta('finalproj.yaml') # create manta python instance using yaml
  
for i in range(1000):
    a = m.lab8_io_core.gx.get() # Read gx
    if (a >> 16 & (1 << (16 - 1))) != 0:
        a = a - (1 << 16) - 72
        
    b = m.lab8_io_core.gy.get() # Read gy
    if (b & (1 << (16 - 1))) != 0:
        b = b - (1 << 16) - 607

    c = m.lab8_io_core.gz.get() # Read gy
    if (c & (1 << (16 - 1))) != 0:
        c = c - (1 << 16) - 65
    
    print(f"gx: {a}, gy: {b}, gz: {c}")
    

