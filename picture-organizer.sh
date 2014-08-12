#!/bin/sh

#Create temp directory
mkdir -p ./!
mkdir -p ./jpg_with_exif_data
mkdir -p ./jpg_no_exif_data
mkdir -p ./jpg

# If you ran this script multiple times it's better to move out files from
# temp folders
mkdir -p ./jpg2
mkdir -p ./!2
mv ./jpg/* ./jpg2/
mv ./!/* ./!2/

#Find all jpgs and list then in txt with absolute paths
find "`pwd`" -iname "*.jpg" > all_jpg.txt

# Set counter to make unique file names
counter=0
randomtemp=0

# List all files and save filename to $line variable
cat all_jpg.txt | while read line
do

# Increase counter
counter=$((counter+1))

# Create variables
# $line variable has full path
filename=$(basename "$line")        # e.g. image-1-2-34.jpg
extension="${line##*.}"             # e.g. jpg
filename_wo_ext="${filename%%.*}"   # e.g. image-1-2-34

# Check if jpg has original date taken EXIF information
if exiftool "$line" |grep -q Original
then
	echo "$line"
	echo " --> EXIF Date Taken found!"
	echo " --> Move to ./jpg_with_exif_data/"

    # Move file to . folder
    # Check if there's is duplicate file, if not
    if [ ! -f ./jpg_with_exif_data/$filename ]; then
    
        # Move file to . folder
        mv -v "$line" ./jpg_with_exif_data/

        # Rename file according to EXIF information
        exiv2 -r '%Y-%m-%d_%H-%M-%S_'"$counter"'' rename "./jpg_with_exif_data/$filename"
    
    else
    
        # File already exists, add random number in the file name before moving
        # the file. We want to avoid replacing files.
        echo "File ./jpg_with_exif_data/$filename exits, adding random number to file name"
        randomtemp="${RANDOM}"
        newfilename="${filename_wo_ext}"_"${randomtemp}.${extension}"
        mv -v "$line" ./jpg_with_exif_data/$newfilename

        # Rename file according to EXIF information
        exiv2 -v -r '%Y-%m-%d_%H-%M-%S_'"$counter"'' rename "./jpg_with_exif_data/$newfilename"
    fi

else
	echo "$line"
	echo " --> No EXIF Date Taken!"
	echo " --> Move to ./!/"
    
    # Move file to ./! folder
    # Check if there's is duplicate file, if not
    if [ ! -f ./!/$filename ]; then
        # Move file to . folder
        mv -v "$line" ./!/
    else
        # File already exists, add random number in the file name
        echo "File ./!/$filename exits, adding random number to file name"
        mv -v "$line" ./!/$filename_wo_ext"_"$RANDOM.$extension
    fi
fi

echo ----------------------
echo

done

# Now all files with EXIF information (with $RANDOM added to name in case
# duplicate file names in multiple directories) are located in the . folder
# and all the files without EXIF information are located in ./!/ folder.

# Now the magic part
touch ./!/*

# Run fdupes to delete all duplicate files. If there are duplicate files
# which has EXIF information and not, duplicates in ./!/ will be deleted
# because fdupes keeps the oldest file, but since we just touched all the
# non-exif files in ./!/ folder, they will be deleted in case of dupes.

echo Run fdupes to delete all duplicate  files.
fdupes -rdN .
echo fdupes done.

#
#   [+] ./9433_12087.jpg
#   [-] ./!/9433_12087.jpg
#
#
#   [+] ./7351_9723.jpg
#   [-] ./!/7351_9723.jpg
#

# Move files from temp folder
mv ./!/* ./jpg_no_exif_data
mv ./jpg_with_exif_data/* ./jpg/

# Delete temp files and folders
rmdir ./!
rmdir ./jpg_with_exif_data
rmdir ./jpg2
rmdir ./!2
rm all_jpg.txt


