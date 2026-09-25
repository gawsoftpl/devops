#!/bin/sh

# Force unbuffered output so stdout/stderr flushes immediately to Docker logs
export RUST_LOG=${RUST_LOG:-"info"}
export RUSTFS_OBS_LOGGER_LEVEL=${RUSTFS_OBS_LOGGER_LEVEL:-"info"}
export RUSTFS_OBS_LOG_STDOUT_ENABLED=${RUSTFS_OBS_LOG_STDOUT_ENABLED:-"true"}

RUSTFS_URL=${RUSTFS_URL:-"http://127.0.0.1:9000"}
RUSTFS_USER=${RUSTFS_ROOT_USER:-"minio"}
RUSTFS_PASS=${RUSTFS_ROOT_PASSWORD:-"minio123"}

create_bucket() {
  BUCKET_NAME="$1"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT \
    --aws-sigv4 "aws:amz:us-east-1:s3" \
    --user "$RUSTFS_USER:$RUSTFS_PASS" \
    "$RUSTFS_URL/$BUCKET_NAME")

  if [ "$HTTP_CODE" -eq 200 ]; then
    echo "[INFO] Successfully created bucket: $BUCKET_NAME" >&2
  elif [ "$HTTP_CODE" -eq 409 ]; then
    echo "[INFO] Bucket '$BUCKET_NAME' already exists." >&2
  else
    echo "[WARN] Bucket creation for '$BUCKET_NAME' responded with status: $HTTP_CODE" >&2
  fi
}

# 1. Launch RustFS in background, forcing standard streams directly to stdout/stderr
rustfs --console-address ":9001" /data &
RUSTFS_PID=$!

# Ensure process clean-up on exit
trap 'kill -TERM $RUSTFS_PID 2>/dev/null' INT TERM EXIT

# 2. Wait for RustFS API connection quietly
echo "[INFO] Waiting for RustFS server to start..." >&2
until curl -s -f -o /dev/null \
  --aws-sigv4 "aws:amz:us-east-1:s3" \
  --user "$RUSTFS_USER:$RUSTFS_PASS" \
  "$RUSTFS_URL" 2>/dev/null; do
  sleep 1
done

echo "[INFO] RustFS is ready." >&2

# 3. Create default buckets
create_bucket "test"
create_bucket "bucket"

# 4. Create buckets from ENV: CREATE_BUCKETS
if [ -n "$CREATE_BUCKETS" ]; then
  for BUCKET in $(echo "$CREATE_BUCKETS" | tr ',' ' '); do
    echo "[INFO] Creating bucket: $BUCKET" >&2
    create_bucket "$BUCKET"
  done
fi

echo "[INFO] Initialization completed. Handing over control to RustFS process..." >&2

# Keep script running and wait on the actual RustFS process
wait "$RUSTFS_PID"