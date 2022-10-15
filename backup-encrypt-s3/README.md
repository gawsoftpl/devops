# Overall
Encrypt file vith age encryption and copy to s3 bucket via restic

## Requirements env
```
AGE_PUBLIC_KEY=age14yhyz50kycgd3umvncpqflh25dh85ru6syjpthrkwvshlap4ly6s44edaz
RESTIC_PASSWORD="backup"
RESTIC_REPOSITORY="s3:https://s3.wasabisys.com/your-bucket-name"
AWS_ACCESS_KEY_ID="your-Wasabi-Access-Key"
AWS_SECRET_ACCESS_KEY="your-Wasasbi-Secret-Key"
```

## Example policy for wasabi:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::bucket",
        "arn:aws:s3:::bucket/*"
      ]
    }
  ]
}
```