#==============================================================================
# A list of some useful commands, which are too rare to remember it,
# but still applicable
#
# @see https://blog.axisful.info/snippets/bash An article on my blog
#==============================================================================

# Processes
#==============================================================================
# Kill the processes by name / when pkill is not an option
for p in $(ps aux | grep -i httpd.worker | cut -d " " -f 4,5); do kill $p; done

# Print process' parents by PID
ps -ocommand= -p $PID | awk -F/ '{print $NF}' | awk '{print $1}'

# Top 5 processes by consumed memory
ps -eo pmem,pcpu,vsize,pid,cmd | sort -k 1 -nr | head -5
free -m

# Files
#==============================================================================
# Replace a string in file
perl -pi -e 's/search/replace/g' file.txt

# Replace a string in multiple files
find . -type f -exec sed -i 's/search/replace/g' {} +

# Check if file exists (I always forget args name)
if ! [ -e $1 ] || [ -z $1 ]; then
  echo "File ${1} doesnt exists"
  exit 1
fi

# Check list of files (print non-existing)
for line in $(cat mylist.log); do if ! [ -e "$line" ]; then echo $line; fi; done

# Display directories' sizes on the partition where the checking dir is mounted
# (saves time for large directories like /)
du -hx --max-depth=1 /

# Compress files with password
7z a -p'paswword' -xr!"*.log" /tmp/${archive_name}.7z ${src_path} > /dev/null

# ZIP: compress with datestamp in name
zip -r ~/tmp/archive-$(date +%Y-%m-%d-%H-%M-%S).zip . -x '*node_modules*'

# TAR GZIP/BZIP: compress with datestamp in name
tar cfvz ~/tmp/archive-$(date +%Y-%m-%d-%H-%M-%S).tar.gz . --exclude "cache"
tar cfvj ~/tmp/archive-$(date +%Y-%m-%d-%H-%M-%S).tar.bz2 . --exclude "cache"

# Send a file to Google Disk
# gdrive must be installed. The hash is a directory's uniq id (could be found with gdrive)
gdrive upload --parent 0B9ILkUWzQMQy3Q2hscGXaNX0zUXc ~/myfile.bz2

# Media
#==============================================================================
# Convert to MP3
lame -b 192 file.wav file.mp3

# Modify MP3 file's bitrate
lame --mp3input -b $bitrate file.mp3 destination.mp3

# Print resolution for images with size > 900KB
identify -format "%Wx%H\n" $(find . -size +900k -type f)

# Set width=900px for any images with width > 900px
mogrify -resize '900x99999>' -quality 90 ./*.jpeg

# Misc
#==============================================================================
# Print packages with architecture (though not really useful nowadays)
rpm -qa --qf '%{NAME}.%{ARCH}\n'

# Dates formatting
formatted_date="$(date +%Y-%m-%d-%H-%M)"

# Set system date and time through CLI: MMDDHHmmYYYY.SS (MonthDayHoursMinutesYear.Seconds
date 091412442012

# RDP connection to Windows PC
rdesktop -g 1366x718 -u User -pPASSWORD -r disk:share=/home/user/shared_dir/ -r sound:off -rclipboard:CLIPBOARD -T RemoteUserHost username

# Backup MySQL database
mysqldump -u user -ppassword database | gzip > backup-database.sql-"$(date +%Y-%m-%d.%H%M%S)".gz

# Mount ntfs partitions
apt install ntfs-config
