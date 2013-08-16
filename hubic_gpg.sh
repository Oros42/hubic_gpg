#!/bin/bash
#
# By Oros & Mitsu
# 2013-08-16
#
# Licence Public Domaine
#
# apt-get install curl
# pacman -S curl

# change login and password
login=""
password=""

if [[ "$login" == "" && "$password" == "" ]]; then
	echo "You need to set login and password !"
	exit 1
fi

if [ "`which curl`" == "" ]; then
	echo "Need cURL !"
	echo "apt-get install curl"
	exit 1
fi

usage="\
Upload and download file from hubiC
$0 -f FILE_TO_UPLOAD|-d FILE_TO_DOWNLOAD [-fo HUBIC_FOLDER_NAME] [-n NEW_FILE_NAME] [-g FILE | -m] [-o LOCAL_OUTPUT_FOLDER] [-r KEY]

-f : file or folder to upload on hubiC
-d : file to download from hubiC
-fo : hubiC folder. Default '/Documents'
-n : new name
-g : file used to hide encrypted data
-m : if no -g, make a gif
-o : local output folder for downloaded file
-r : GPG key
-h : help

Exemples for upload :
$0 -f myfile.txt -fo /Documents
$0 -f myfile.txt -n myfile_backup01.txt
$0 -f myfile.txt -r MyGpGKey
$0 -f myfile.txt -n myfile_backup01.txt -m -r MyGpGKey
$0 -f myfile.txt -n myfile_backup01.txt -g matrix.gif -r MyGpGKey
$0 -f myfile.txt -g matrix.gif -r MyGpGKey
$0 -f myfile.txt -m -r MyGpGKey

Exemples for download :
$0 -d myfile.txt -fo /Documents
$0 -d myfile.txt -r MyGpGKey
$0 -d myfile.txt -o ./my_backup/
$0 -d myfile.txt -o ./my_backup/ -r MyGpGKey"



if [ -z "$1" ]; then
	echo "$usage"
	echo 'error: please append the file to upload.'; exit
fi

if [ -d "/tmp/hubic_output/" ]; then
	rm -r /tmp/hubic_output/
fi
mkdir /tmp/hubic_output/


destination='/Documents'

gif_file=""
output_folder=`pwd`/out
download_file=""
file=""
recipient=""
while test $# -gt 0 ; do
  case $1 in
		-h | --help)
			echo "$usage"
			exit 0
			;;
		-r)
			# Encrypt for user id USER
			recipient=$2
			shift
			shift
			;;
		-f)
			# file or folder to upload on hubiC
			fullfile=$2
			file=$(basename "$fullfile")
			shift
			shift
			;;
		-d)
			# file name to download from hubiC
			download_file=$2
			shift
			shift
			;;
		-fo)
			# hubic folder
			destination=$2
			shift
			shift
			;;
		-n)
			# option
			# new name
			file=$2
			shift
			shift
			;;
		-o)
			# option
			# output folder for downloaded files
			output_folder=$2
			shift
			shift
			;;
		-g)
			# option
			# use a file to hide gpg file
			# can be a gif, jpg, png, zip, avi, mp4,...
			# mp3 : not very good
			gif_file=$2
			shift
			shift
			;;

		-m)
			# option
			# make a gif to hide gpg file
			if [ "`which convert`" == "" ]; then
				echo "Need Image Magic !"
				echo "apt-get install imagemagick"
				exit 1
			else
				# draw a gif
				gif_file="/tmp/hubic_fun.gif"
				convert -size 600x600 xc:white -stroke black -pointsize 200 -draw "text 150,350 ':-)'" $gif_file
				convert $gif_file -rotate 90 $gif_file
				convert $gif_file -stroke black -pointsize 25 -draw "text 60,420 '`date`'" $gif_file
			fi
			shift
			;;
		*)
			echo "ERROR: unknown parameter \"$PARAM\""
			echo "$usage"
			exit 1
			;;
	esac
	shift
done


if [ "$fullfile" != "" ]; then 
	echo "Upload file to hubiC"
	if [ "$recipient" != "" ]; then
		echo "Encrypt file"
		#gpg-zip -e -r "$recipient" -o /tmp/$file $fullfile
		tar -cf - $fullfile | gpg --set-filename x.tar -e -r "$recipient" -o /tmp/$file
		if [ "$gif_file" != "" ]; then
			echo "add gif at begin of file"
			fullfile=/tmp/${file}.${gif_file##*.}
			cp $gif_file $fullfile
			echo "1337 file" >> $fullfile # it use to locate the gif end in the new file
			cat /tmp/$file >> $fullfile
			rm /tmp/$file
			file=${file}.${gif_file##*.}
			# cleening /tmp
			if [ "$gif_file" == "/tmp/hubic_fun.gif" ]; then
				rm /tmp/hubic_fun.gif
			fi
		fi
	else
		if [ -d "$fullfile" ]; then
			echo "Uploading folder not implement"
			exit 1
		fi
	fi

	if [ -f '/tmp/cookiefile' ]; then
		rm '/tmp/cookiefile'
	fi

	echo "logging in..."
	# connection to hubic
	curl -sq --cookie-jar '/tmp/cookiefile' --request GET "https://hubic.com/" >/dev/null
	curl -sq --cookie-jar '/tmp/cookiefile' --request POST --data "sign-in-email=${login}&sign-in-password=${password}" "https://hubic.com/home/actions/nasLogin.php" >/dev/null
	 
	echo "generating file metadata..."
	filesize=$(stat -c%s "$fullfile")
	filesize_human=$(stat -c%s "$fullfile")
	filetype=$(file --mime-type "$fullfile" | awk -F' ' '{print $2}')
	filemtime=$(stat -c %Y "$fullfile")
	filedate=$(date -u --rfc-3339=seconds --date="@$filemtime" | awk -F'+' '{print $1}' | tr " " T)
	 
	# upload the file
	 
	echo "#### summary ####"
	echo "file: $file"
	echo "filepath: $fullfile"
	echo "filesize: $filesize"
	echo "filetype: $filetype"
	echo "file mod date: $filedate"
	echo "destination: $destination"
	echo "#### end summary ####"
	 
	echo "uploading..."
	output=$(curl -sq --cookie '/tmp/cookiefile' --request PUT -H "Content-Type:$filetype" -H "Content-Disposition:attachment; filename='$file'" -H "X-File-Name:$file" -H "X-File-Type:$filetype" -H "X-File-Size:$filesize" -H 'X-Action:upload' -H "X-File-Dest:$destination" -H 'X-File-Container:default' -H "X-File-Modified:$filedate" -H 'X-Requested-With:XMLHttpRequest' -H "Content-Length:$filesize" -H 'Connection:keep-alive' -T "$fullfile" 'https://hubic.com/home/actions/ajax/hubic-browser.php')
	echo "upload done."
	echo "server response: "
	echo $output
	 
	# log off
	curl  -s --cookie --request GET "https://hubic.com/home/actions/logoff.php" >/dev/null
	rm '/tmp/cookiefile'

	if [[ "$recipient" != "" && "$gif_file" != "" ]]; then
		rm $fullfile
	fi
	echo "== end of script =="
	echo ""
	echo "Done"
fi

if [ "$download_file" != "" ]; then
	# Download file from hubiC

	if [ -f '/tmp/cookiefile' ]; then
		rm '/tmp/cookiefile'
	fi

	echo "logging in..."
	# connection to hubic
	curl -sq --cookie-jar '/tmp/cookiefile' --request GET "https://hubic.com/" >/dev/null
	curl -sq --cookie-jar '/tmp/cookiefile' --request POST --data "sign-in-email=${login}&sign-in-password=${password}" "https://hubic.com/home/actions/nasLogin.php" >/dev/null
	
	# dowload file
	echo "Downloading..."
	curl -s --cookie /tmp/cookiefile --request POST --data "action=download&container=default&isFile0=true&uri=/${destination}/${download_file}&name=${download_file}&fileCount=1" "https://hubic.com/home/actions/ajax/hubic-browser.php" > /tmp/$download_file
	echo "ok"
	# log off
	curl  -s --cookie --request GET "https://hubic.com/home/actions/logoff.php" >/dev/null
	rm /tmp/cookiefile

	if [ ! -d "$output_folder" ]; then
		mkdir -p $output_folder
	fi

	if [ "$recipient" != "" ]; then
		# Decrypt
		echo "Decrypt..."
		have_gif=$(grep -a "1337 file" /tmp/$download_file)
		if [ "$have_gif" != "" ]; then
			echo "Remove gif"
			# remove gif from file
			sed -i '0,/1337 file/d' /tmp/$download_file
		fi
		home=`pwd`
		cd /tmp/hubic_output
		#gpg-zip -d -r "$recipient" /tmp/$download_file
		cat "/tmp/$download_file" | gpg -d -r "$recipient" | tar -xvf -
		rm /tmp/$download_file
		echo "Move file to $output_folder/"
		mv /tmp/hubic_output/* $output_folder/
		cd $home
	else
		echo "Move file to $output_folder/"
		mv /tmp/$download_file $output_folder/
	fi
	echo "Done"
fi
rm -r /tmp/hubic_output/
