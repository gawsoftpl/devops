#!/bin/sh

RUSTFS_URL=${RUSTFS_URL:-"http://127.0.0.1:9000"}
RUSTFS_USER=${RUSTFS_ROOT_USER:-"minio"}
RUSTFS_PASS=${RUSTFS_ROOT_PASSWORD:-"minio123"}

# Ensure standard output/error flush continuously
export PYTHONUNBUFFERED=1

# Helper function to create a bucket via signed S3 API call
create_bucket() {
  BUCKET_NAME="$1"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT \
    --aws-sigv4 "aws:amz:us-east-1:s3" \
    --user "$RUSTFS_USER:$RUSTFS_PASS" \
    "$RUSTFS_URL/$BUCKET_NAME")

  if [ "$HTTP_CODE" -eq 200 ]; then
    echo "[INFO] Successfully created bucket: $BUCKET_NAME"
  elif [ "$HTTP_CODE" -eq 409 ]; then
    echo "[INFO] Bucket '$BUCKET_NAME' already exists."
  else
    echo "[WARN] Bucket creation for '$BUCKET_NAME' responded with status: $HTTP_CODE"
  fi
}

# 1. Start RustFS server in the background, keeping stdout/stderr unbuffered
rustfs --console-address ":9001" /data &
RUSTFS_PID=$!

# 2. Wait for RustFS API connection quietly
echo "[INFO] Waiting for RustFS server to start..."
until curl -s -f -o /dev/null \
  --aws-sigv4 "aws:amz:us-east-1:s3" \
  --user "$RUSTFS_USER:$RUSTFS_PASS" \
  "$RUSTFS_URL" 2>/dev/null; do
  sleep 1
done

echo "[INFO] RustFS is ready."

# 3. Create default buckets
create_bucket "test"
create_bucket "bucket"

# 4. Create buckets from ENV: CREATE_BUCKETS
if [ -n "$CREATE_BUCKETS" ]; then
  for BUCKET in $(echo "$CREATE_BUCKETS" | tr ',' ' '); do
    echo "[INFO] Creating bucket from ENV: $BUCKET"
    create_bucket "$BUCKET"
  done
fi

echo "[INFO] Initialization completed. RustFS running..."

# Wait for background process so script doesn't exit prematurely
wait "$RUSTFS_PID"