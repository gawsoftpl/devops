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


# For ubuntu check that age and awscli is installed
age --version
if [[ $? -gt 0 ]];
then
  apt install -y age
fi

aws --version
if [[ $? -gt 0 ]];
then
  apt install -y awscli
fi

# Encrypt file
cat $FILE | age -r $BACKUP_ENCRYPTION_AGE_PUBLIC_KEY > $enc_file

export AWS_SHARED_CREDENTIALS_FILE=/tmp/aws-credentials
export AWS_CONFIG_FILE=/tmp/aws-config

cat <<EOF > $AWS_SHARED_CREDENTIALS_FILE
[default]
region=$S3_REGION
aws_access_key_id=$S3_ACCESS_KEY
aws_secret_access_key=$S3_SECRET_KEY
EOF

cat <<EOF > $AWS_CONFIG_FILE
[default]
s3 =
  max_concurrent_requests = 20
  multipart_chunksize = 64MB

EOF

# Copy to s3
aws s3 cp --endpoint-url=https://${S3_ENDPOINT} $enc_file s3://${S3_BUCKET}/${S3_FOLDER}
rm $enc_file
rm $FILE

# Retention
# Remove old files from s3
files_limit=${RETENTION_MAX_FILES}
files_index=0
aws s3 ls --endpoint-url=https://${S3_ENDPOINT} s3://${S3_BUCKET}/${S3_FOLDER} | tac | while read -r line;  do
files_index=$(expr $files_index + 1)
createDate=`echo $line|awk {'print $1" "$2'}`
createDate=`date -d"$createDate" +%s`
olderThan=`date -d"-$RETENTION_FILE_MAX_DAYS days" +%s`
if [ $createDate -lt $olderThan ] && [ $files_index -gt $files_limit ]
then
    fileName=`echo $line|awk '{$1=$2=$3=""; print $0}' | sed 's/^[ \t]*//'`
    echo $fileName
    if [ $fileName != "" ]
    then
        aws s3 rm --endpoint-url=https://${S3_ENDPOINT} "s3://${S3_BUCKET}/${S3_FOLDER}$fileName"
        echo "COMPLETED S3"

    fi
fi
done;


rm $AWS_SHARED_CREDENTIALS_FILE
rm $AWS_CONFIG_FILE
