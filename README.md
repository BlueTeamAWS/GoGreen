# S3 bucket with Cross-Region Replication (CRR); lifecycle rules; server side encryption ; static website hosting ; Cross-origin-resoutce-sharing rules (CORS) ; and versioning enabled.
# CloudFront WEB Distribution enabled.

Configuration in this directory creates S3 bucket in one region and configures CRR to another bucket in another region.

Please check [complete example](https://github.com/terraform-aws-modules/terraform-aws-s3-bucket/tree/master/examples/complete) to see all other features supported by this module.

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these resources.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| aws.replica | n/a |
| random | n/a |

## Inputs

No input.

## Outputs

| Name | Description |
|------|-------------|
| this\_s3\_bucket\_arn | The ARN of the bucket. Will be of format arn:aws:s3:::bucketname. |
| this\_s3\_bucket\_bucket\_domain\_name | The bucket domain name. Will be of format bucketname.s3.amazonaws.com. |
| this\_s3\_bucket\_bucket\_regional\_domain\_name | The bucket region-specific domain name. The bucket domain name including the region name, please refer here for format. Note: The AWS CloudFront allows specifying S3 region-specific endpoint when creating S3 origin, it will prevent redirect issues from CloudFront to S3 Origin URL. |
| this\_s3\_bucket\_hosted\_zone\_id | The Route 53 Hosted Zone ID for this bucket's region. |
| this\_s3\_bucket\_id | The name of the bucket. |
| this\_s3\_bucket\_region | The AWS region this bucket resides in. |
| this\_s3\_bucket\_website\_domain | The domain of the website endpoint, if the bucket is configured with a website. If not, this will be an empty string. This is used to create Route 53 alias records. |
| this\_s3\_bucket\_website\_endpoint | The website endpoint, if the bucket is configured with a website. If not, this will be an empty string. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
