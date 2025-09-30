#!/usr/bin/env bash
# set -x
#
# Written by Mike Studer
# Sep 20 2025
#
#=============== User Configuration ============================================
# Location of the received satellite directories created by GOES based on date (mainly)
# For an example: '2025-08-25_20-03_goes_hrit_1.6941 GHz'
# This is designed to decipher GOES-19 HRIT data directories and extract the
# pretty pictures.  And then make GIF videos.

base_dir=( /home/mstuder/HydraSDR/*/)
# I assume that images are taken from a GOES-18 HRIT downlink directory.
# The HRIT data is full of time based directories each containing a sets of pictures

# Output directory for picture files
sat_pictures="/home/mstuder/Pictures/Satellite-Pictures/"
# The pictures will be passed into magick to create a timelapse video
# The animated GIF goes here...
sat_videos="/home/mstuder/Videos/Satellite-Videos/"

sat_array=(GOES-18 GOES-19 Himawari)

# ------ Functions ------

Kounter() {
  # There should not be more that 99 pictures in each dir
  if [ "$knt" -le 99 ]; then
     padded_counter=$(printf "%02d" "$knt")
  fi
}

Find_the_file() {
    # Search through all the files in ONE dir for the image file we want
    #echo "DEBUG: sfile = $sfile"
    for sdir in "$sfile"/*; do
       # Test if any of the files in the dir is the one we want
       if [[ $sdir == *"$p_img" ]]; then
          echo "$sdir FOUND"
          Kounter
          cp "$sdir" "$sat_pictures/$selsat/$dname/image_$padded_counter.png"
          ((knt++))
       fi
    done
}

Output_dir_create() {
   # Output file setup
   # Test to see if there is an existing place to put the image files for a specific day
   dname=$(echo "$fobj" | cut -d '/' -f5 | cut -d '_' -f1 )
   #echo "DEBUG: dname = $dname"
   # Create directories for PICTURES
      if [ -d "$sat_pictures$selsat/$dname" ]; then
          echo "Directory exists, continuing $sat_pictures$dname"
      else
         # Create a new dir for the images based on time stamp
         mkdir -p "$sat_pictures$selsat/$dname"
      fi
   # Create directories for VIDEOS
      if [ -d "$sat_videos/$selsat/$dname" ]; then
          echo "Directory exists, continuing $sat_videos/$dname"
      else
         # Create a new dir for the images based on time stamp
         mkdir -p "$sat_videos/$selsat/$dname"
      fi
}

Copy_the_image() {
   ((knt=1))
   for sfile in "$tdir"/*; do
      if [ -d "$sfile" ]; then
         # This is where the input file gets copied to output directory
         Find_the_file
      fi
   done
}

Make_animation() {
   # To stack images into a video. Save these lines for reference.
   # ffmpeg -f image2 -pattern_type glob -i 'pic_*.png' -c:v libx264 -pix_fmt yuv420p -framerate 24 output.mp4
   # I prefer Image Magick solution
   # magick -delay 60  -loop 0 image??.png -scale 25% myimage_25.gif
   echo
   echo "Creating the gif video from images.  This takes a while."
   magick -delay 60 -loop 0 "$sat_pictures/$selsat/$dname/image_??.png" -scale 30% "$sat_videos/$selsat/$dname/$selsat-video.gif"
   echo "Created, $sat_videos/$selsat/$dname/$selsat-video.gif"
}

# -------- MAIN Loop --------
# PS3 is an environment variable that serves as the prompt string for the select command.
PS3="Select a directory date to process: "
select dir in "${base_dir[@]}"; do
   [[ "$dir" ]] &&
      {
      fobj="$dir"
      break
      }
   echo "Invalid selection"
done
echo "You selected $fobj Continuing ..."
# Check if the provided base path contains valid directory
for selsat in "${sat_array[@]}"; do
   if [[ $selsat == "GOES-18" ]]; then
      dir_path="IMAGES/GOES-18/Full Disk/"
      #   GOES-18 preferred image abi_rgb_ABI_False_Color_map.png
      p_img="abi_rgb_ABI_False_Color_map.png"
   elif [[ $selsat == "GOES-19" ]]; then
      dir_path="IMAGES/GOES-19/Full Disk/"
      #   GOES-19 preferred image bi_rgb_Clean_Longwave_IR_Window_Band_map.png
      p_img="abi_rgb_Clean_Longwave_IR_Window_Band_map.png"
   elif [[ $selsat == "Himawari" ]]; then
      dir_path="IMAGES/Himawari/"
      #   Himawari preferred image ahi_rgb_AHI_False_Color_(WIP)_map.png
      p_img="ahi_rgb_AHI_False_Color_(WIP)_map.png"
   else
      echo "ERROR: satellite not found, exiting"
      exit
   fi

   tdir="$fobj$dir_path"
   echo
   echo  "Directory to process, $tdir "
   #ls "$tdir"

   Output_dir_create
   Copy_the_image
   Make_animation
done

echo
echo "All done. Thanks for using this script! Have a nice day."
