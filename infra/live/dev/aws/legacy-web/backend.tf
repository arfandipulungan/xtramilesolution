# Remote state: S3 (versioned, SSE-KMS, public access blocked) with native S3
# state locking (use_lockfile, Terraform >= 1.10); no DynamoDB table needed.
terraform {
  backend "s3" {
    bucket       = "xtramile-tfstate-dev-apse2"
    key          = "dev/aws/legacy-web.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    use_lockfile = true
  }
}
