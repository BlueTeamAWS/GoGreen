# main.tf

terraform {

  required_version = ">= 0.12"
  backend "s3" {
    encrypt = true
    bucket  = "gogreen-3tier-tf-state"
    region  = "us-west-2"
    key     = "terraform/state/gogreen3tier.tfstate"
  }
}

locals {
  bucket_name             = "origin-s3-bucket-gogreen"
  destination_bucket_name = "replica-s3-bucket-gogreen"
  origin_region           = "eu-west-1" # Ireland
  replica_region          = "sa-east-1" # Sao Paulo
}
provider "aws" {
  region = local.origin_region
}
provider "aws" {
  region = local.replica_region
  alias  = "replica"
}
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "replica" {
  provider                = aws.replica
  description             = "S3 bucket replication KMS key"
  deletion_window_in_days = 7
}
module "log_bucket" {
  source                         = "github.com/terraform-aws-modules/terraform-aws-s3-bucket?ref=v1.9.0"
  bucket                         = "logs-${local.bucket_name}"
  acl                            = "log-delivery-write"
  force_destroy                  = true
  attach_elb_log_delivery_policy = true
}
module "replica_bucket" {
  source = "github.com/terraform-aws-modules/terraform-aws-s3-bucket?ref=v1.9.0"
  providers = {
    aws = "aws.replica"
  }
  bucket = local.destination_bucket_name
  region = local.replica_region
  acl    = "private"
  versioning = {
    enabled = true
  }
}
module "s3_bucket" {
  source = "github.com/terraform-aws-modules/terraform-aws-s3-bucket?ref=v1.9.0"
  bucket = local.bucket_name
  region = local.origin_region
  acl    = "private"
  versioning = {
    enabled = true
  }
  replication_configuration = {
    role = aws_iam_role.replication.arn
    rules = [
      {
        id       = "foo"
        status   = "Enabled"
        priority = 10
        source_selection_criteria = {
          sse_kms_encrypted_objects = {
            enabled = true
          }
        }
        filter = {
          prefix = "one"
          tags = {
            ReplicateMe = "Yes"
          }
        }
        destination = {
          bucket             = "arn:aws:s3:::${local.destination_bucket_name}"
          storage_class      = "STANDARD"
          replica_kms_key_id = aws_kms_key.replica.arn
          account_id         = data.aws_caller_identity.current.account_id
          access_control_translation = {
            owner = "Destination"
          }
        }
      },
      {
        id       = "bar"
        status   = "Enabled"
        priority = 20
        destination = {
          bucket        = "arn:aws:s3:::${local.destination_bucket_name}"
          storage_class = "STANDARD"
        }
        filter = {
          prefix = "two"
          tags = {
            ReplicateMe = "Yes"
          }
        }
      },
    ]
  }

  website = {
    index_document = "index.html"
    error_document = "error.html"
    routing_rules = jsonencode([{
      Condition : {
        KeyPrefixEquals : "docs/"
      },
      Redirect : {
        ReplaceKeyPrefixWith : "documents/"
      }
    }])

  }

  logging = {
    target_bucket = module.log_bucket.this_s3_bucket_id
    target_prefix = "log/"
  }
  cors_rule = [
    {
      allowed_methods = ["PUT", "POST"]
      allowed_origins = ["https://modules.tf", "https://terraform-aws-modules.modules.tf"]
      allowed_headers = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
      }, {
      allowed_methods = ["PUT"]
      allowed_origins = ["https://example.com"]
      allowed_headers = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]

  lifecycle_rule = [
    {
      id      = "log"
      enabled = true
      prefix  = "log/"

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 30
          storage_class = "ONEZONE_IA"
          }, {
          days          = 60
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 90
      }

      noncurrent_version_expiration = {
        days = 30
      }
    },
    {
      id                                     = "log1"
      enabled                                = true
      prefix                                 = "log1/"
      abort_incomplete_multipart_upload_days = 7

      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 60
          storage_class = "ONEZONE_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
      ]

      noncurrent_version_expiration = {
        days = 300
      }
    },
  ]

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.objects.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  object_lock_configuration = {
    object_lock_enabled = "Enabled"
    rule = {
      default_retention = {
        mode  = "COMPLIANCE"
        years = 5
      }
    }
  }

  // S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}