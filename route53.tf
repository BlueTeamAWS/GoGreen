# Route53_alias.tf
provider "aws" {
  region = var.region
}

module "route53_alias" {
  source = "git@github.com:cloudposse/terraform-aws-route53-alias"

  aliases         = var.aliases
  parent_zone_id  = var.parent_zone_id
  target_zone_id  = var.target_zone_id
  target_dns_name = var.target_dns_name
}

variable "region" {
  type    = string
  default = "us-west-1" # Type your region
}

variable "aliases" {
  type        = list(string)
  description = "List of aliases"
  default     = ["test-alias"] # Type your alias
}

variable "parent_zone_id" {
  type        = string
  description = "ID of the hosted zone to contain this record "
  default     = "Z08533508ZO3K7C0UQL8" # Type your Parent Zone ID
}

variable "target_zone_id" {
  type        = string
  description = "ID of target resource (e.g. ELB)"
  default     = "Z368ELLRRE2KJ0" # Type your Target Zone ID
}

variable "target_dns_name" {
  type        = string
  description = "DNS name of target resource (e.g. ELB)"
  default     = "test-load-balancer-1445063994.us-west-1.elb.amazonaws.com."
}

output "hostnames" {
  value       = module.route53_alias.hostnames
  description = "List of DNS records"
}

output "parent_zone_id" {
  value       = module.route53_alias.parent_zone_id
  description = "ID of the hosted zone to contain the records"
}

output "parent_zone_name" {
  value       = module.route53_alias.parent_zone_name
  description = "Name of the hosted zone to contain the records"
}
