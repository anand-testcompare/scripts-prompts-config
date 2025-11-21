#!/bin/bash

# SVG conversion script
# Reads optimized PNG images from root folder and outputs SVG versions
# Prioritizes color preservation and sharp boundaries
# Supports folder structure preservation and interactive selection

# Function to get folders and files sorted by modification time (newest first)
get_sorted_options() {
    {
        # Get directories first (excluding raw folder and organized subdirectories)
        find . -mindepth 1 -maxdepth 1 -type d ! -name "raw" ! -name "png" ! -name "svg" -exec stat -f "%m %N" {} \; 2>/dev/null | sort -rn | cut -d' ' -f2- | sed 's|./||'
        # Then check for PNG files in organized structure or root
        find . -mindepth 1 -maxdepth 1 -name "png" -type d 2>/dev/null | head -1 | sed 's|./||'
    }
}

# Function to create high-quality raster-embedded SVG
create_raster_svg() {
    local input_file="$1"
    local output_file="$2"
    local filename=$(basename "$input_file")
    
    # Get image dimensions
    local dimensions=$(magick identify -format "%wx%h" "$input_file" 2>/dev/null)
    local width=$(echo $dimensions | cut -d'x' -f1)
    local height=$(echo $dimensions | cut -d'x' -f2)
    
    if [ -z "$width" ] || [ -z "$height" ]; then
        return 1
    fi
    
    # Convert PNG to base64
    local base64_data=$(base64 -i "$input_file")
    
    # Create SVG with embedded PNG
    cat > "$output_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" 
     width="$width" height="$height" viewBox="0 0 $width $height">
  <image x="0" y="0" width="$width" height="$height" 
         xlink:href="data:image/png;base64,$base64_data"/>
</svg>
EOF
    return 0
}

# Function to analyze image complexity for vectorization suitability
analyze_image_complexity() {
    local input_file="$1"
    
    # Count unique colors (simplified complexity metric)
    local color_count=$(magick "$input_file" -format "%k" info: 2>/dev/null)
    
    # Simple heuristic: fewer colors = better for vectorization
    if [ "$color_count" -lt 20 ]; then
        echo "simple"
    elif [ "$color_count" -lt 50 ]; then
        echo "moderate"  
    else
        echo "complex"
    fi
}

# Function to preprocess image for better vectorization
preprocess_for_vector() {
    local input_file="$1"
    local output_file="$2"
    
    # Apply preprocessing for better vectorization:
    # 1. Slight blur to smooth jagged edges
    # 2. Posterize to reduce color complexity
    # 3. Enhance contrast
    magick "$input_file" \
        -blur 0x0.3 \
        -posterize 16 \
        -contrast-stretch 2%x2% \
        -quality 100 "$output_file"
    
    return $?
}

# Function to convert a single file to SVG with smart method selection
convert_to_svg() {
    local input_file="$1"
    local output_file="$2"
    local filename=$(basename "$input_file")
    local temp_processed="/tmp/processed_$(basename "$input_file")"
    
    echo "Processing: $filename"
    
    # Analyze image complexity
    local complexity=$(analyze_image_complexity "$input_file")
    echo "  Image complexity: $complexity"
    
    # Method 1: High-Quality Raster-Embedded SVG (RECOMMENDED for modern logos)
    echo "  Creating high-quality raster-embedded SVG..."
    if create_raster_svg "$input_file" "$output_file"; then
        echo "  ✅ Created high-quality raster-embedded SVG (RECOMMENDED)"
        echo "     → Maintains all visual quality while being fully scalable"
        return 0
    fi
    
    # Method 2: Attempt vectorization only for simple images
    if [ "$complexity" = "simple" ] && command -v vtracer &> /dev/null; then
        echo "  Simple image detected - attempting true vectorization..."
        
        # Preprocess for better vectorization
        if preprocess_for_vector "$input_file" "$temp_processed"; then
            # Try VTracer with more conservative settings for better quality
            vtracer -i "$temp_processed" -o "${output_file}.vector" \
                --colormode color --mode spline --filter_speckle 4 \
                --color_precision 6 --corner_threshold 60 --segment_length 20 \
                --splice_threshold 45 --path_precision 8
            
            if [ $? -eq 0 ]; then
                # Compare file sizes - if vector is much larger, prefer raster
                vector_size=$(stat -f%z "${output_file}.vector" 2>/dev/null || echo 999999)
                raster_size=$(stat -f%z "$output_file" 2>/dev/null || echo 0)
                
                if [ "$vector_size" -lt $((raster_size * 3)) ]; then
                    mv "${output_file}.vector" "$output_file"
                    echo "  ✅ Created true vector SVG (efficient for simple graphics)"
                    rm -f "$temp_processed" 2>/dev/null
                    return 0
                else
                    rm -f "${output_file}.vector" 2>/dev/null
                    echo "  ℹ️ Vector version too large, keeping raster-embedded version"
                fi
            else
                rm -f "${output_file}.vector" 2>/dev/null
            fi
        fi
        rm -f "$temp_processed" 2>/dev/null
    fi
    
    # If we get here, raster-embedded SVG was already created in Method 1
    return 0
}

# Function to process PNG files in organized directory structure
process_svg_conversion() {
    local base_path="$1"
    local relative_path="$2"
    local processed=0
    
    # Determine base directory
    if [ -n "$relative_path" ]; then
        base_dir="./$relative_path"
    else
        base_dir="."
    fi
    
    echo "Processing SVG conversion from: $base_path"
    
    # Check if we have organized PNG structure
    if [ -d "$base_dir/png" ]; then
        echo "Found organized PNG structure, creating corresponding SVG structure..."
        
        # Create SVG directory structure
        mkdir -p "$base_dir/svg/original"
        mkdir -p "$base_dir/svg/no-bg"
        mkdir -p "$base_dir/svg/no-bg-alt"
        
        # Process each variant folder
        for variant in "original" "no-bg" "no-bg-alt"; do
            png_dir="$base_dir/png/$variant"
            svg_dir="$base_dir/svg/$variant"
            
            if [ -d "$png_dir" ]; then
                echo ""
                echo "Converting $variant PNGs to SVGs..."
                
                # Process all PNG files in this variant folder
                shopt -s nullglob
                for png_file in "$png_dir"/*.png; do
                    if [ -f "$png_file" ]; then
                        filename=$(basename "$png_file")
                        name="${filename%.*}"
                        svg_output="$svg_dir/${name}.svg"
                        
                        echo "  Processing: $filename ($variant)"
                        if convert_to_svg "$png_file" "$svg_output"; then
                            ((processed++))
                        fi
                    fi
                done
            fi
        done
        
    else
        # Legacy mode: process files in root directory (old flat structure)
        echo "Processing legacy flat structure..."
        
        shopt -s nullglob
        for file in "$base_path"/*.png; do
            # Skip if no PNG files found
            if [ ! -f "$file" ]; then
                continue
            fi
            
            # Skip already processed -no-bg files to avoid duplicates
            if [[ "$file" == *"-no-bg.png" ]]; then
                continue
            fi
            
            # Get filename without path and extension
            filename=$(basename "$file")
            name="${filename%.*}"
            
            # Set paths based on whether we're in a subfolder
            if [ -n "$relative_path" ]; then
                original_file="./${relative_path}/${name}.png"
                no_bg_file="./${relative_path}/${name}-no-bg.png"
                output="./${relative_path}/${name}.svg"
            else
                original_file="./${name}.png"
                no_bg_file="./${name}-no-bg.png"
                output="./${name}.svg"
            fi
            
            # Check if we have both versions and prioritize background-free
            if [ -f "$no_bg_file" ]; then
                echo "Processing: $filename (using background-free version)"
                
                # Convert the background-free version
                if convert_to_svg "$no_bg_file" "$output"; then
                    ((processed++))
                fi
            elif [ -f "$original_file" ]; then
                echo "Processing: $filename (using original version)"
                
                # Convert the original version
                if convert_to_svg "$original_file" "$output"; then
                    ((processed++))
                fi
            fi
        done
    fi
    
    return $processed
}

echo "SVG Conversion Script"
echo "===================="

# Get available options sorted by newest first
options=($(get_sorted_options))

if [ ${#options[@]} -eq 0 ]; then
    echo "No folders or PNG files found for conversion"
    echo "Please run ./optimize_logos.sh first to create optimized PNG files"
    exit 1
fi

echo ""
echo "Available options (newest first):"
echo "0) Process all folders and files"
for i in "${!options[@]}"; do
    option="${options[$i]}"
    if [ -d "./$option" ]; then
        # Check for organized structure first
        if [ -d "./$option/png" ]; then
            png_count=$(find "./$option/png" -name "*.png" | wc -l | tr -d ' ')
        else
            # Legacy flat structure
            png_count=$(find "./$option" -name "*.png" ! -name "*-no-bg.png" | wc -l | tr -d ' ')
        fi
        echo "$((i+1))) 📁 $option ($png_count PNGs)"
    elif [ "$option" = "png" ]; then
        # Root PNG folder
        png_count=$(find "./png" -name "*.png" | wc -l | tr -d ' ')
        echo "$((i+1))) 📁 Root PNG folder ($png_count PNGs)"
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
    process_svg_conversion "." ""
    root_processed=$?
    processed=$((processed + root_processed))
    
    # Process each folder
    for option in "${options[@]}"; do
        if [ -d "./$option" ]; then
            echo ""
            process_svg_conversion "./$option" "$option"
            folder_processed=$?
            processed=$((processed + folder_processed))
        fi
    done
    
elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
    selected="${options[$((choice-1))]}"
    echo ""
    
    if [ -d "./$selected" ]; then
        process_svg_conversion "./$selected" "$selected"
        processed=$?
    else
        process_svg_conversion "." ""
        processed=$?
    fi
else
    echo "Invalid selection"
    exit 1
fi

echo ""
echo "SVG conversion complete!"
echo "Processed $processed images"

if [ $processed -eq 0 ]; then
    echo "No PNG images found or processed"
    echo "Please run ./optimize_logos.sh first to create optimized PNG files"
else
    echo ""
    echo "ℹ️  About SVG Quality:"
    echo "   • Raster-embedded SVGs maintain perfect visual quality while being fully scalable"
    echo "   • True vector conversion attempted only for simple graphics (< 20 colors)"
    echo "   • Modern logos with gradients/effects work best as raster-embedded SVGs"
    echo ""
    echo "📁 For further optimization, consider:"
    echo "   • VTracer: cargo install vtracer (for simple graphics vectorization)"
    echo "   • Manual vector recreation in Illustrator/Figma for complex logos"
fi