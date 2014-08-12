picture-organizer-sh
====================

Scans (find) folder for jpg files, differentiates jpgs without EXIF information, deletes all duplicate files (fdupes) and renames jpg files according to Date Taken/Date Original EXIF information.

This is by far an optimized solution. It's slow but it does the job :)

Dependencies
====================
- mv
- find
- fdupe
- exiv2

Usage
====================
    $ cd /path/to/picture/collection/20144/trip/helsinki
    $ ./picture-organizer.sh
    
Output
====================
    - 'jpg' folder
    -- All jpgs file with EXIF information renamed according to EXIF Date Original field.
    - 'jpg_no_exif_data
    -- All jpgs without EXIF information with their original names expect added random string in case file already exists in the destination location.

e.g.:

    otto@pc:~/Git/picture-organizer-sh$ ls -l /media/Storage/Pictures/Unsorted/
    total 520
    drwxrwxr-x 2 1024 users 294912 elo   12 22:00 jpg
    drwxrwxr-x 2 1024 users 237568 elo   12 21:48 jpg_no_exif_data

and

    otto@pc:~/Git/picture-organizer-sh$ ls -l /media/Storage/Pictures/Unsorted/jpg/
    total 8996776
    -rwxr-xr-x 1 1024 users  1006278 huhti 21 20:16 2004-02-28_20-45-42_5926.jpg
    -rwxr-xr-x 1 1024 users   273551 huhti 21 20:09 2004-03-14_14-47-43_9640.jpg
    -rwxr-xr-x 1 1024 users   263044 huhti 21 20:23 2004-03-14_14-48-00_11415.jpg
    -rwxr-xr-x 1 1024 users    45174 huhti 21 20:17 2004-03-21_02-45-02_4154.jpg
    -rwxr-xr-x 1 1024 users   360176 huhti 21 20:10 2004-03-26_10-40-38_8068.jpg
    -rwxr-xr-x 1 1024 users   338491 huhti 21 20:24 2004-03-26_10-40-49_10197.jpg
    -rwxr-xr-x 1 1024 users   366268 huhti 21 20:23 2004-04-21_15-31-54_9415.jpg
    -rwxr-xr-x 1 1024 users   332368 huhti 21 20:23 2004-04-21_18-20-37_11347.jpg
    -rwxr-xr-x 1 1024 users   348987 huhti 21 20:24 2004-04-21_18-21-37_10874.jpg
    -rwxr-xr-x 1 1024 users   366923 huhti 21 20:17 2004-04-22_09-51-41_11305.jpg
    
Use with your own risk :)

