# Python script to format a string of raw bytes into a hexadecimal escape sequence string
# DigitalAndrew
import sys

def format_to_hex_esc_sequence(raw_bytes):
    # Split the string into chunks of two characters
    bytes = [raw_bytes[i:i+2] for i in range(0, len(raw_bytes), 2)]
    # Add "\x" in front of each chunk
    hex_escape_sequence = ''.join(f'\\x{byte}' for byte in bytes)
    return hex_escape_sequence

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python shellcode_format.py <input_string>")
        sys.exit(1)

    input_string = sys.argv[1]
    result = format_to_hex_esc_sequence(input_string)
    print(result)