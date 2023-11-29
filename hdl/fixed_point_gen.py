import math
def float_to_fixed(f,e):
    a = abs(f)* (2**e)
    b = int(round(a))
    if f < 0:
        b_binary = ''
        for bit in bin(b)[2:]:
          if bit == '1':
            b_binary += '0'
          else:
            b_binary += '1'
        b = int(b_binary, 2) + 1
    return b
  
for i in range(181):
  rad = math.radians(i)
  sin_val = math.sin(rad)
  if (i != 360):
    fixed_sin_val = float_to_fixed(sin_val,16)
  if (i == 0 or i == 360):
    print(f"8'd{i}: amp_out <= 32'b00000000000000000000000000000000")
  elif (i == 90):
    print(f"8'd{i}: amp_out <= 32'b00000000000000010000000000000000")
  elif (i == 270):
    print(f"8'd{i}: amp_out <= 32'b11111111111111110000000000000000")
  elif (i < 180):
    string = f"0000000000000000{bin(fixed_sin_val)[2:]}"
    for j in range(16 - (len(bin(fixed_sin_val)) - 2)):
      string = '0' + string
    print(f"8'd{i}: amp_out <= 32'b{string}")
  else:
    string = f"{bin(fixed_sin_val)[2:]}"
    for j in range(16 - (len(bin(fixed_sin_val)[2:]))):
      if j == 16 - (len(bin(fixed_sin_val)[2:])) - 1:
        string = '1' + string
      else:
        string = '0' + string
    print(f"8'd{i}: amp_out <= 32'b1111111111111111{string}")
    