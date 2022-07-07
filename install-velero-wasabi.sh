#!/bin/bash

printf "Enter wasabi access_key:\n"
read access_key

printf "Enter wasabi secret_key:\n"
read secret_key

printf "Enter wasabi endpoint example: [s3.us-central-1.wasabisys.com]:\n"
read endpoint

printf "Enter wasabi region [us-central-1]:\n"
read region

printf "Enter wasabi bucket name:\n"
read bucket

use_restic=""
while [[ $use_restic != "0" && $use_restic != "1" ]];
do
  printf "Do you want to use restic? [0 - no, 1 - yes]:\n"
  read use_restic
done

# Create credentials
cat << EOF > /tmp/wasabi
[default]
aws_access_key_id=${access_key}
aws_secret_access_key=${secret_key}
EOF

cmd="velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.5.0 \
  --bucket ${bucket} \
  --secret-file /tmp/wasabi \
  --backup-location-config region=${region},s3ForcePathStyle="true",s3Url=http://${endpoint} \
  --snapshot-location-config region=${region}
  "

if [ $use_restic = "1" ];
then
  cmd+=' --use-restic'
fi

# Execute
$cmd

rm /tmp/wasabi