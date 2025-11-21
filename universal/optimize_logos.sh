#!/bin/bash

# Logo optimization script
# Reads images from ./raw/ folder and outputs optimized versions to root folder
# Max size: 1000x1000, high quality preservation
# Supports folder structure preservation and interactive selection

# Check if raw folder exists
if [ ! -d "./raw" ]; then
    echo "Error: ./raw folder not found"
    echo "Please create a ./raw folder and place your images there"
    exit 1
fi

# Check if ImageMagick is available
if ! command -v magick &> /dev/null; then
    echo "Error: ImageMagick not found"
    echo "Please install ImageMagick: brew install imagemagick"
    exit 1
fi

# Function to get folders and files sorted by modification time (newest first)
get_sorted_options() {
    {
        # Get directories first
        find ./raw -mindepth 1 -maxdepth 1 -type d -exec stat -f "%m %N" {} \; 2>/dev/null | sort -rn | cut -d' ' -f2- | sed 's|./raw/||'
        # Then get files
        find ./raw -mindepth 1 -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) -exec stat -f "%m %N" {} \; 2>/dev/null | sort -rn | cut -d' ' -f2- | sed 's|./raw/||'
    }
}

# Function to process files in a directory or single file
process_images() {
    local source_path="$1"
    local relative_path="$2"
    local processed=0
    
    echo "Processing images from: $source_path"
    
    # Create output directory structure if needed
    if [ -n "$relative_path" ]; then
        base_dir="./$relative_path"
    else
        base_dir="."
    fi
    
    # Create organized folder structure
    mkdir -p "$base_dir/png/original"
    mkdir -p "$base_dir/png/no-bg"
    mkdir -p "$base_dir/png/no-bg-alt"
    
    if [ -n "$relative_path" ]; then
        echo "Created organized directory structure: ./$relative_path"
    else
        echo "Created organized directory structure in root"
    fi
    
    # Process all common image formats
    shopt -s nullglob
    for file in "$source_path"/*.png "$source_path"/*.jpg "$source_path"/*.jpeg "$source_path"/*.PNG "$source_path"/*.JPG "$source_path"/*.JPEG; do
        
        # Get filename without path and extension
        filename=$(basename "$file")
        name="${filename%.*}"
        
        # Set organized output paths
        output_original="$base_dir/png/original/${name}.png"
        output_no_bg="$base_dir/png/no-bg/${name}.png"
        output_no_bg_alt="$base_dir/png/no-bg-alt/${name}.png"
        
        echo "Processing: $filename"

        # Version 1: Resize with high quality, keep original background
        magick "$file" -resize 1000x1000 -quality 95 "$output_original"

        if [ $? -eq 0 ]; then
            echo "  ✓ Original version: $output_original"

            # Detect if background is light or dark by sampling all four corners
            # Get average brightness of all corners (0-255 scale, 0=black, 255=white)
            nw_brightness=$(magick "$file" -gravity northwest -crop 10x10+0+0 +repage -colorspace gray -format "%[fx:mean*255]" info:)
            ne_brightness=$(magick "$file" -gravity northeast -crop 10x10+0+0 +repage -colorspace gray -format "%[fx:mean*255]" info:)
            sw_brightness=$(magick "$file" -gravity southwest -crop 10x10+0+0 +repage -colorspace gray -format "%[fx:mean*255]" info:)
            se_brightness=$(magick "$file" -gravity southeast -crop 10x10+0+0 +repage -colorspace gray -format "%[fx:mean*255]" info:)

            # Calculate average of all corners
            corner_brightness=$(echo "scale=2; ($nw_brightness + $ne_brightness + $sw_brightness + $se_brightness) / 4" | bc)
            corner_brightness_int=$(printf "%.0f" "$corner_brightness")

            # Determine background type: <=160 is dark, >160 is light
            # This threshold works better for distinguishing dark grays from light backgrounds
            if [ "$corner_brightness_int" -le 160 ]; then
                bg_type="dark"
                bg_color="Black"
                target_color="black"
                echo "  → Detected dark background (brightness: $corner_brightness_int)"
            else
                bg_type="light"
                bg_color="White"
                target_color="white"
                echo "  → Detected light background (brightness: $corner_brightness_int)"
            fi

            # Version 2: Advanced background removal with flood fill and anti-aliasing
            # This method provides superior edge quality compared to simple -transparent
            magick "$file" -resize 1000x1000 \
                -bordercolor "$bg_color" -border 1 \
                -fuzz 10% -fill none -draw "alpha 0,0 floodfill" \
                -channel alpha -blur 0x0.5 -level 50x100% +channel \
                -shave 1x1 -quality 95 "$output_no_bg"

            if [ $? -eq 0 ]; then
                echo "  ✓ Background-free version: $output_no_bg"

                # Version 3: Alternative method using blurred mask compositing
                # This can work better for images with complex edges or internal areas
                magick "$file" -resize 1000x1000 \
                    \( +clone -fuzz 15% -transparent "$target_color" -blur 0x1 \) \
                    -compose copy_opacity -composite -quality 95 "$output_no_bg_alt"

                if [ $? -eq 0 ]; then
                    echo "  ✓ Alternative background-free version: $output_no_bg_alt"
                else
                    echo "  ✗ Failed to create alternative background-free version: $filename"
                fi

                ((processed++))
            else
                echo "  ✗ Failed to create background-free version: $filename"
            fi
        else
            echo "  ✗ Failed to process: $filename"
        fi
    done
    
    return $processed
}

echo "Logo Optimization Script"
echo "======================="

# Get available options sorted by newest first
options=($(get_sorted_options))

if [ ${#options[@]} -eq 0 ]; then
    echo "No folders or image files found in ./raw/"
    echo "Supported formats: PNG, JPG, JPEG"
    exit 1
fi

echo ""
echo "Available options (newest first):"
echo "0) Process all folders and files"
for i in "${!options[@]}"; do
    option="${options[$i]}"
    if [ -d "./raw/$option" ]; then
        file_count=$(find "./raw/$option" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) | wc -l | tr -d ' ')
        echo "$((i+1))) 📁 $option ($file_count images)"
    else
        echo "$((i+1))) 📄 $option"
    fi
done

echo ""
read -p "Select option (0-${#options[@]}): " choice

processed=0

if [ "$choice" = "0" ]; then
    echo ""
    echo "Processing all folders and files..."
    
    # Process root level files first
    process_images "./raw" ""
    root_processed=$?
    processed=$((processed + root_processed))
    
    # Process each folder
    for option in "${options[@]}"; do
        if [ -d "./raw/$option" ]; then
            echo ""
            process_images "./raw/$option" "$option"
            folder_processed=$?
            processed=$((processed + folder_processed))
        fi
    done
    
elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
    selected="${options[$((choice-1))]}"
    echo ""
    
    if [ -d "./raw/$selected" ]; then
        process_images "./raw/$selected" "$selected"
        processed=$?
    else
        process_images "./raw" ""
        processed=$?
    fi
else
    echo "Invalid selection"
    exit 1
fi

echo ""
echo "Optimization complete!"
echo "Processed $processed images"

if [ $processed -eq 0 ]; then
    echo "No images found or processed"
    echo "Supported formats: PNG, JPG, JPEG"
fi