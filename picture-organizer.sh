#!/bin/bash

# See README.md for guide

## Parameters

# Minimum width not to be considered as a thumb
min_width=640
    
# Set counter to make unique file names
counter=0
randomtemp=0
curdir=`pwd`

check_and_delete_empty_dir () { 
  
    if [ -d "$1" ]; then
        #echo "$1" exists
        shopt -s nullglob dotglob
        files=("$1"/*)
        (( ${#files[*]} )) || rmdir "$1" #echo "$1" is empty
        shopt -u nullglob dotglob
    fi
}

dir_exists_and_is_empty () { 
  
    is_dir_empty=0
    
    if [ -d "$1" ]; then
        #echo "$1" exists
        shopt -s nullglob dotglob
        files=("$1"/*)
        (( ${#files[*]} )) || is_dir_empty=1
        shopt -u nullglob dotglob
    fi

}


#Create temp directory
mkdir -p "$curdir"/!
mkdir -p "$curdir"/jpg_with_exif_data
mkdir -p "$curdir"/jpg_no_exif_data
mkdir -p "$curdir"/jpg
mkdir -p "$curdir"/thumbs

# If you ran this script multiple times and ctrl+c'd it's better to move 
# out files from temp folders
dir_exists_and_is_empty "$curdir/jpg"
if [ $is_dir_empty -eq 1 ]; then
    mkdir -p ./jpg2; mv ./jpg/* ./jpg2/; fi 

dir_exists_and_is_empty "$curdir/!"
if [ $is_dir_empty -eq 1 ]; then
    mkdir -p ./!2;   mv ./!/* ./!2/; fi 

#Find all jpgs and list then in txt with absolute paths
echo "Searching for jpgs... this may take a while"
find "`pwd`" -type f -iname "*.jpg" > all_jpg.txt
totaljpgs=cat all_jpg.txt | wc -l
echo
# List all files and save filename to $line variable
cat all_jpg.txt | while read line
do

# Increase counter
counter=$((counter+1))
totaljpgs=$(cat all_jpg.txt | wc -l)
procentdone=$(echo "scale=2; $counter/$totaljpgs*100" | bc)
# Create variables
# $line variable has full path
filename=$(basename "$line")        # e.g. image-1-2-34.jpg
extension="${line##*.}"             # e.g. jpg
filename_wo_ext="${filename%%.*}"   # e.g. image-1-2-34

# Check if jpg has original date taken EXIF information and
# If picture doesn't have camera model, move to -/! folder

cameramodel=$(exiftool "$line" | grep -e "Camera Model" -m 1 | awk '{print $NF}' 2>&1)
dateoriginal=$(exiftool "$line" |grep "Date/Time Original")
#dateoriginal=$(exiftool "$line" |grep -q "Date/Time Original")

echo "[$counter/$totaljpgs ($procentdone%)] $line"
               
if [ -n "$dateoriginal" -a -n "$cameramodel" ]
then
	echo " --> EXIF Date Original: $dateoriginal"

    # Move file to . folder
    # Check if there's is duplicate file, if not
    if [ ! -f "./jpg_with_exif_data/$filename" ]; then
       
        # If Image width is less than $min_width let's assume it's a thumbnail
        imgwidth=$(exiftool "$line" | grep -v "Exif Image Width" | grep "Image Width" -m 1 | awk '{print $NF}' 2>&1)

        if [ $imgwidth -lt $min_width ]
        then
            # Move file to folder
            echo "   --> Image Width $imgwidth < $min_width"
            echo "   --> and"
            echo "   --> Camera Model Empty: $cameramodel"
        	echo " --> Move to ./thumbs/"
            mv "$line" "$curdir"/thumbs/

            # Rename file according to EXIF information
            exiv2 -r '%Y-%m-%d_%H-%M-%S_'"$counter"'' rename "./thumbs/$filename"
        
        else  
        
            # Move file to folder
            echo "   --> Image Width $imgwidth >= $min_width"
            echo "   --> and"
            echo "   --> Camera Model is not Empty: $cameramodel"
        	echo " --> Move to ./jpg_with_exif_data/"
            mv "$line" ./jpg_with_exif_data/

            # Rename file according to EXIF information
            exiv2 -r '%Y-%m-%d_%H-%M-%S_'"$counter"'' rename "./jpg_with_exif_data/$filename"
        fi
        
    else
        # TODO IMAGE SKIPS CHECKS
        # File already exists, add random number in the file name before moving
        # the file. We want to avoid replacing files.
        echo "File ./jpg_with_exif_data/$filename exits, adding random number to file name"
        randomtemp="${RANDOM}"
        newfilename="${filename_wo_ext}"_"${randomtemp}.${extension}"
        mv "$line" ./jpg_with_exif_data/$newfilename

        # Rename file according to EXIF information
        exiv2 -v -r '%Y-%m-%d_%H-%M-%S_'"$counter"'' rename "./jpg_with_exif_data/$newfilename"
    fi

else
	echo " --> No EXIF Date Original: $dateoriginal"
    echo " --> or"
    echo " --> Camera Model is Empty: $cameramodel"
	echo " --> Move to ./!/"
    
    # Move file to ./! folder
    # Check if there's is duplicate file, if not
    if [ ! -f "./!/$filename" ]; then
        # Move file to . folder
        mv "$line" ./!/
    else
        # File already exists, add random number in the file name
        echo "File ./!/$filename exits, adding random number to file name"
        mv "$line" ./!/$filename_wo_ext"_"$RANDOM.$extension
    fi
fi

echo ----------------------
echo

done

# Now all files with EXIF information (with $RANDOM added to name in case
# duplicate file names in multiple directories) are located in the . folder
# and all the files without EXIF information are located in ./!/ folder.

# Now the magic part
dir_exists_and_is_empty "$curdir/!"
if [ $is_dir_empty -eq 0 ]; then
    find "$curdir/!" -type f -print0 | xargs -0 touch
fi

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

dir_exists_and_is_empty "$curdir/!"
if [ $is_dir_empty -eq 0 ] 
then
    mv "$curdir/!/"* "$curdir/jpg_no_exif_data/"
    #mv -v ./!/* ./jpg_no_exif_data/
fi

dir_exists_and_is_empty "$curdir/jpg_with_exif_data"
if [ $is_dir_empty -eq 0 ] 
then
    mv "$curdir/jpg_with_exif_data/"* "$curdir/jpg/"
    #mv ./jpg_with_exif_data/* ./jpg/
fi

# Delete temp files and folders
check_and_delete_empty_dir "$curdir/!"
check_and_delete_empty_dir "$curdir/jpg_with_exif_data"

if [ -d "`pwd`/jpg2" ]; then rmdir "`pwd`/jpg2" ; fi 
if [ -d "`pwd`/!2" ]; then rmdir "`pwd`/!2" ; fi 
rm all_jpg.txt

# Move files other files than jpg to 'other' folder
mkdir -p "$curdir"/other

find "$curdir" -type f ! -iname "*.jpg" ! -iname "all_other.txt" > all_other.txt

if [ -s all_other.txt ]
then
    cat all_other.txt | while read line
    do
        mv -v -t "$curdir"/other "$line"
    done
    
fi

rm all_other.txt

if [ -d other ]
then
    # Check if other folder contains videos (MIME TYPE: video/*) and move them to
    # videos folder
    mkdir -p "`pwd`"/videos
    mkdir -p "`pwd`"/raw
    mkdir -p "`pwd`"/gif

    find "`pwd`"/other -type f > all_other2.txt
    cat all_other2.txt | while read line
    do
        if exiftool "$line" |grep -q "video/"
        then
            mv -v -t "`pwd`/videos" "$line" 
        
        # If MIME type is canon cr2 move to raw folder
        elif exiftool "$line" |grep -q "x-canon-cr2"
        then
            mv -v -t "`pwd`/raw" "$line" 
 
        # If MIME type is image/gif move to gif folder
        elif exiftool "$line" |grep -q "image/gif"
        then
            mv -v -t "`pwd`/gif" "$line" 
        fi
    done
fi

# Try to rename videos according to date

# Delete folder if exists and empty
check_and_delete_empty_dir "$curdir/jpg"
check_and_delete_empty_dir "$curdir/jpg_no_exif_data"
check_and_delete_empty_dir "$curdir/other"
check_and_delete_empty_dir "$curdir/raw"
check_and_delete_empty_dir "$curdir/videos"
check_and_delete_empty_dir "$curdir/gif"
check_and_delete_empty_dir "$curdir/thumbs"
rm all_other2.txt

# Scan for corrupted image files
echo
echo Scan corrupted jpg files...
find "$curdir" -iname "*.jpg" -type f > "$curdir"/jpgs.txt
if [ -s jpgs.txt ]
then
    echo Lets move corrupted images if any...
    mkdir -p "$curdir"/corrupted/warnings
    mkdir -p "$curdir"/corrupted/errors

    cat "$curdir"/jpgs.txt | while read line
    do
        if $(jpeginfo -c "$line" | grep -q "ERROR")
        then
            echo ERROR: "$line"
            mv -v "$line" "$curdir"/corrupted/errors/
        fi
    done
    rmdir "$curdir"/corrupted/errors/
    
    cat "$curdir"/jpgs.txt | while read line
    do
        if $(jpeginfo -c "$line" | grep -q "WARNING")
        then
            echo WARNING: "$line"
            mv "$line" "$curdir"/corrupted/warnings/
        fi
    done
    
    rmdir "$curdir"/corrupted/warnings/
    
    rmdir "$curdir"/corrupted
    
    #if [ -d "$curdir"/corrupted ]
    #then 
    #    echo Check corrupted folder!
    #fi
fi

rm "$curdir"/jpgs.txt

