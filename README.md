hubic_gpg
=========

Bash upload and download file from hubiC  


Setup
=====

Need cURL to work
```shell
apt-get install curl
```

And optionnal Image Magick
```shell
apt-get install imagemagick
```

```shell
chmod +x hubic_gpg.sh
```

Parameters
==========

```shell
./hubic_gpg.sh -f FILE_TO_UPLOAD|-d FILE_TO_DOWNLOAD [-fo HUBIC_FOLDER_NAME] [-n NEW_FILE_NAME] [-g FILE | -m] [-o LOCAL_OUTPUT_FOLDER] [-r KEY]
```

-f : file or folder to upload on hubiC  
-d : file to download from hubiC  
-fo : hubiC folder. Default '/Documents'  
-n : new name  
-g : file used to hide encrypted data  
-m : if no -g, make a gif  
-o : local output folder for downloaded file  
-h : help  

Examples for upload : 
```shell
./hubic_gpg.sh -f myfile.txt -fo /Documents
./hubic_gpg.sh -f myfile.txt -n myfile_backup01.txt
./hubic_gpg.sh -f myfile.txt -r MyGpGKey
./hubic_gpg.sh -f myfile.txt -n myfile_backup01.txt -m -r MyGpGKey
./hubic_gpg.sh -f myfile.txt -n myfile_backup01.txt -g matrix.gif -r MyGpGKey
./hubic_gpg.sh -f myfile.txt -g matrix.gif -r MyGpGKey
./hubic_gpg.sh -f myfile.txt -m -r MyGpGKey
```
Examples for download : 
```shell
./hubic_gpg.sh -d myfile.txt -fo /Documents
./hubic_gpg.sh -d myfile.txt -r MyGpGKey
./hubic_gpg.sh -d myfile.txt -o ./my_backup/
./hubic_gpg.sh -d myfile.txt -o ./my_backup/ -r MyGpGKey
```
