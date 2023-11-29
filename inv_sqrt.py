def float_to_fixed_point(value):
    # Convert the floating-point number to a 32-bit integer
    fixed_point_value = int(value * (2**16))

    # Convert the integer to binary representation with 32 bits
    binary_representation = bin(fixed_point_value & 0xFFFFFFFF)[2:].zfill(32)

    # Split the binary representation into integer and fractional parts
    integer_part = binary_representation[:16]
    fractional_part = binary_representation[16:]

    # Convert binary parts to decimal
    integer_part_decimal = int(integer_part, 2)
    fractional_part_decimal = int(fractional_part, 2)

    # Construct the fixed-point representation string
    fixed_point_string = f"32'sh{integer_part_decimal:08x}{fractional_part_decimal:04x}"

    return fixed_point_string

def generate_inverse_sqrt_table():
    table = ""
    for i in range(31, 0, -1):
        estimate_x = 2 ** i / 2 ** 16
        estimate_y = 1 / (estimate_x ** .5)
        sqrt_in = f"sqrtIn[{i}]"
        sqrt_guess = float_to_fixed_point(estimate_y)
        # print(f"estimate_x: {estimate_x}\n, estimate_y: {estimate_y}\n, sqrt_guess: {sqrt_guess}\n")
        table += f"\telse if ({sqrt_in}) guess = {sqrt_guess};\n"
    
    # Default case for sqrtIn[0]
    table += f"\telse guess = 32'sh00200000;\n"

    return table

# Generate and print the table
table_content = generate_inverse_sqrt_table()
print(f"if ({table_content}")
print("\n\n")
print("fixed 1.5: ", float_to_fixed_point(1.5))      
print("fixed .5: ", float_to_fixed_point(.5))      
