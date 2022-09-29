#!/bin/bash
SAVE_DIR=${SAVE_DIR:-'/tmp'}
date=`date +%Y-%b-%d-%H:%M:%S`
enc_file=${SAVE_DIR}/backup-${date}.age
RETENTION_MAX_FILES=${RETENTION_MAX_FILES:-100}
RETENTION_FILE_MAX_DAYS=${RETENTION_FILE_MAX_DAYS:-90}

if [ ${#FILE} -eq 0 ];
then
  echo "No set file ENV"
  exit 2
fi

if [ ! -f $FILE ];
then
  echo "$FILE not exists"
  exit 2
fi


# Check that required tools is installed
age --version
if [[ $? -gt 0 ]];
then
  wget -O /tmp/age.tar.gz https://github.com/FiloSottile/age/releases/download/v1.0.0/age-v1.0.0-linux-amd64.tar.gz
  tar -xvf /tmp/age.tar.gz
  chmod +x /tmp/age/age
  cp /tmp/age/age /usr/bin
fi

s5cmd --version
if [[ $? -gt 0 ]];
then
  wget -O /tmp/s5cmd.tar.gz https://github.com/peak/s5cmd/releases/download/v2.0.0/s5cmd_2.0.0_Linux-64bit.tar.gz
  tar -xvf /tmp/s5cmd.tar.gz
  chmod +x /tmp/s5cmd
  mv /tmp/s5cmd /usr/bin
fi

# Encrypt file
cat $FILE | age -r $AGE_PUBLIC_KEY > $enc_file

# Copy to s3
s5cmd cp $enc_file s3://${S3_BUCKET}/${S3_FOLDER}
rm $enc_file
rm $FILE

# Retention
# Remove old files from s3
[ if ${#RETENTION_FILE_MAX_DAYS} -gt 0 ];
then
  files_limit=${RETENTION_MAX_FILES}
  files_index=0
  is_dir=`echo $line | grep DIR`
  if [ ${#is_dir} -eq 0 ];
  then
    s5cmd ls s3://${S3_BUCKET}/${S3_FOLDER} | tac | while read -r line;  do
    files_index=$(expr $files_index + 1)
    createDate=`echo $line|awk {'print $1" "$2'}`
    if [ ${#createDate} -gt 0 ];
      createDate=`date -d"$createDate" +%s`
      olderThan=`date -d"-$RETENTION_FILE_MAX_DAYS days" +%s`
      if [ $createDate -lt $olderThan ] && [ $files_index -gt $files_limit ]
      then
          fileName=`echo $line|awk '{$1=$2=$3=""; print $0}' | sed 's/^[ \t]*//'`
          echo $fileName
          if [ $fileName != "" ]
          then
              s5cmd rm "s3://${S3_BUCKET}/${S3_FOLDER}${fileName}"
              echo "$fileName removed"

          fi
      fi
    fi
  fi
  done;
fi
