import time
import struct 
from pandas import DataFrame
from manta import Manta
m = Manta('finalproj.yaml') # create manta python instance using yaml
  
for i in range(1000):
    a = m.lab8_io_core.gx.get() # Read gx 
    if (a >> 32 & (1 << (32 - 1))) != 0:
      a = a - (1 << 32)
    a_final = struct.unpack('f', struct.pack('i', a))[0]
    
    b = m.lab8_io_core.gy.get() # Read gy
    if (b & (1 << (32 - 1))) != 0:
      b = b - (1 << 32) 
    b_final = struct.unpack('f', struct.pack('i', b))[0]
    
    c = m.lab8_io_core.gz.get() # Read gy
    if (c & (1 << (32 - 1))) != 0:
      print('here')
      c = c - (1 << 32) 
    c_final = struct.unpack('f', struct.pack('i', c))[0]
    
    print(f"pitch: {a}, roll: {b}, yaw: {c}")
    

