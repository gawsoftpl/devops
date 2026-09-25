#!/bin/sh

RUSTFS_URL=${RUSTFS_URL:-"http://127.0.0.1:9000"}
RUSTFS_USER=${RUSTFS_ROOT_USER:-"minio"}
RUSTFS_PASS=${RUSTFS_ROOT_PASSWORD:-"minio123"}

# 1. Start RustFS server in the background
rustfs --console-address ":9001" /data &

# Helper function to create a bucket via signed S3 API call
create_bucket() {
  BUCKET_NAME="$1"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT \
    --aws-sigv4 "aws:amz:us-east-1:s3" \
    --user "$RUSTFS_USER:$RUSTFS_PASS" \
    "$RUSTFS_URL/$BUCKET_NAME")

  if [ "$HTTP_CODE" -eq 200 ]; then
    echo "Successfully created bucket: $BUCKET_NAME"
  elif [ "$HTTP_CODE" -eq 409 ]; then
    echo "Bucket '$BUCKET_NAME' already exists."
  else
    echo "Bucket creation for '$BUCKET_NAME' responded with status: $HTTP_CODE"
  fi
}

# 2. Wait for RustFS API connection
until curl -s -o /dev/null \
  --aws-sigv4 "aws:amz:us-east-1:s3" \
  --user "$RUSTFS_USER:$RUSTFS_PASS" \
  "$RUSTFS_URL" > /dev/null 2>&1; do
  echo "Wait for connect with rustfs $RUSTFS_URL..."
  sleep 1
done

# 3. Create default buckets
create_bucket "test"
create_bucket "bucket"

# 4. Create buckets from ENV: CREATE_BUCKETS
if [ -n "$CREATE_BUCKETS" ]; then
  # Zamiana przecinków na spacje i iteracja
  for BUCKET in $(echo "$CREATE_BUCKETS" | tr ',' ' '); do
    echo "Creating bucket: $BUCKET"
    create_bucket "$BUCKET"
  done
fi

echo "Completed."

wait
