# =============================================================================
# variables.tf — Input variable declarations
#
# These define WHAT values the configuration accepts.
# The actual values are set in terraform.tfvars (see that file).
# =============================================================================

variable "region" {
  description = "AWS region to deploy all resources into"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name — used as a prefix on every resource name and tag"
  type        = string
  default     = "student102"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g. 172.40.0.0/16)"
  type        = string
  default     = "172.40.0.0/16"
}

variable "slo_cidr" {
  description = "CIDR block for the public (SLO) subnet — must be within vpc_cidr"
  type        = string
  default     = "172.40.1.0/24"
}

variable "sli_cidr" {
  description = "CIDR block for the private (SLI) subnet — must be within vpc_cidr"
  type        = string
  default     = "172.40.2.0/24"
}

variable "ami_id" {
  description = <<-EOT
    Amazon Machine Image (AMI) ID for the EC2 instance.
    AMI IDs are region-specific — update this if you change your region.
    Region reference:
      us-east-1      = ami-0c02fb55956c7d316  (default, Amazon Linux 2)
      us-east-2      = ami-0b0dcb5067f052a63
      us-west-1      = ami-0d9858aa3c6322f73
      us-west-2      = ami-0ceecbb0f30a902a6
      eu-west-1      = ami-0d71ea30463e0ff49
      ap-southeast-1 = ami-078c1149d8ad719a7
  EOT
  type    = string
  default = "ami-08a006458983be57e"
}

variable "instance_type" {
  description = "EC2 instance type (e.g. t3.micro, t3.small, t3.medium)"
  type        = string
  default     = "m5.2xlarge"
}

variable "volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 80
}

# =============================================================================
# F5 XC CE Registration Variables (used by cloud_init.tf → user_data.tpl)
# =============================================================================

variable "f5xc_registration_token" {
  description = <<-EOT
    The site registration token generated from the F5 Distributed Cloud console.
    How to get it:
      1. Log in to https://console.ves.volterra.io
      2. Go to: Multi-Cloud Network Connect → Manage → Site Management → Site Tokens
      3. Click "Add Site Token", give it a name, copy the token value
      4. Paste it into terraform.tfvars as f5xc_registration_token = "..."

    This value is marked sensitive — Terraform will never print it in plan/apply output.
  EOT
  type      = string
  sensitive = true   # prevents the token from appearing in terraform plan/apply logs
}

variable "f5xc_cluster_name" {
  description = <<-EOT
    The name you gave this CE site in the F5 XC console.
    This must exactly match the site name configured in:
      Multi-Cloud Network Connect → Manage → Site Management → Sites
    Example: "my-aws-ce-site"
  EOT
  type = string
}

variable "f5xc_certified_hardware" {
  description = <<-EOT
    The certified hardware profile for this CE node.
    For AWS deployments running the F5 XC CE AMI this is almost always:
      "aws-byol-voltmesh"        — single NIC (SLO only), most common
      "aws-byol-multi-nic-voltmesh" — dual NIC (SLO + SLI)
    Leave the default unless F5 support tells you otherwise.
  EOT
  type    = string
  default = "aws-byol-voltmesh"
}

variable "f5xc_latitude" {
  description = <<-EOT
    Geographic latitude of this CE site (decimal degrees).
    Used by F5 XC to place the site on the world map in the console.
    Example: 51.5074 for London, 37.3861 for Silicon Valley.
    Find your coordinates at: https://www.latlong.net
  EOT
  type    = number
  default = 0
}

variable "f5xc_longitude" {
  description = <<-EOT
    Geographic longitude of this CE site (decimal degrees).
    Used by F5 XC to place the site on the world map in the console.
    Example: -0.1278 for London, -122.0839 for Silicon Valley.
    Find your coordinates at: https://www.latlong.net
  EOT
  type    = number
  default = 0
}
