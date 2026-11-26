# Brownfield import for infra/live/prod/aws/legacy-web (copy into that folder in a
# migration PR, together with the name_overrides in main.tf; delete after the apply).
#
# Existing, click-built resource: the over-exposed customer files bucket
#   legacyweb-customer-exports
# The bucket and its data stay; the import brings it under the locked-down module,
# so the plan shows exactly which protections get switched on (public access block,
# KMS encryption, versioning, TLS-only + VPC-endpoint-only policy).

import {
  to = module.stack.module.customer_files_bucket.aws_s3_bucket.this
  id = "legacyweb-customer-exports"
}

# Sub-resources that exist only if someone configured them in the console. Import the ones
# that exist (the inventory shows which); the rest are created by the apply.
import {
  to = module.stack.module.customer_files_bucket.aws_s3_bucket_versioning.this
  id = "legacyweb-customer-exports"
}

import {
  to = module.stack.module.customer_files_bucket.aws_s3_bucket_server_side_encryption_configuration.this
  id = "legacyweb-customer-exports"
}

import {
  to = module.stack.module.customer_files_bucket.aws_s3_bucket_policy.this
  id = "legacyweb-customer-exports"
}
