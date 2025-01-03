import OpenEXR
import Imath
import os

input_file = "PfizerOutdoCancer/Resources/lab_v005_corrected.exr"
output_file = "PfizerOutdoCancer/Resources/lab_v005_corrected_piz.exr"

# Open the input file
exr = OpenEXR.InputFile(input_file)

# Get the header
header = exr.header()

# Modify the header to use PIZ compression
header['compression'] = Imath.Compression(Imath.Compression.PIZ_COMPRESSION)

# Create output file with the modified header
out = OpenEXR.OutputFile(output_file, header)

# Copy the data
for channel in header['channels'].keys():
    data = exr.channel(channel)
    out.writePixels({channel: data})

# Close the files
exr.close()
out.close()

# Print file sizes
original_size = os.path.getsize(input_file) / (1024 * 1024)  # MB
compressed_size = os.path.getsize(output_file) / (1024 * 1024)  # MB
print(f"Original size: {original_size:.2f} MB")
print(f"Compressed size: {compressed_size:.2f} MB")
print(f"Compression ratio: {original_size/compressed_size:.2f}x")
