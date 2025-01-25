import bpy
import os
import sys

def process_usdz(input_path):
    # Clear existing mesh objects
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    
    print(f"Importing file: {input_path}")
    
    # Import USDZ
    bpy.ops.wm.usd_import(filepath=input_path)
    
    print("Applying decimation...")
    # Select all mesh objects
    for obj in bpy.context.scene.objects:
        if obj.type == 'MESH':
            obj.select_set(True)
            bpy.context.view_layer.objects.active = obj
            
            # Add decimate modifier
            decimate = obj.modifiers.new(name="Decimate", type='DECIMATE')
            decimate.ratio = 0.3
            
            # Apply the modifier
            bpy.ops.object.modifier_apply(modifier="Decimate")
    
    # Create decimated folder if it doesn't exist
    input_dir = os.path.dirname(input_path)
    output_dir = os.path.join(input_dir, "decimated")
    os.makedirs(output_dir, exist_ok=True)
    
    # Export as USDZ
    filename = os.path.basename(input_path)
    output_path = os.path.join(output_dir, filename)
    print(f"Exporting to: {output_path}")
    bpy.ops.wm.usd_export(filepath=output_path)
    print("Export complete!")

def process_directory(directory_path):
    print(f"Processing directory: {directory_path}")
    # Process each USDZ file in the directory (not recursively)
    for filename in os.listdir(directory_path):
        if filename.lower().endswith('.usdz'):
            input_path = os.path.join(directory_path, filename)
            if os.path.isfile(input_path):
                print(f"\nProcessing: {filename}")
                process_usdz(input_path)

def main():
    # Check if we have a command line argument
    if len(sys.argv) < 2:
        print("Error: Please provide a file or directory path as an argument")
        print("Usage: blender -b -P decimate.py -- <path_to_file_or_directory>")
        sys.exit(1)

    # Get the input path from command line arguments
    # In Blender, arguments after -- are in sys.argv[1:]
    input_path = sys.argv[-1]  # Get the last argument

    if not os.path.exists(input_path):
        print(f"Error: Path does not exist: {input_path}")
        sys.exit(1)

    if os.path.isfile(input_path):
        if not input_path.lower().endswith('.usdz'):
            print("Error: Input file must be a USDZ file")
            sys.exit(1)
        process_usdz(input_path)
    else:
        process_directory(input_path)

    print("\nAll processing complete!")

if __name__ == "__main__":
    main()
