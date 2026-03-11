# =============================================================================
# terraform.tfvars — Actual values for your deployment
#
# Edit the values here before running `terraform apply`.
# This file overrides the defaults set in variables.tf.
# =============================================================================

region  = "us-east-1"
project = "studentx"

# ── Networking ────────────────────────────────────────────────────────────────
vpc_cidr = "172.40.0.0/16"
slo_cidr = "172.40.1.0/24"   # public subnet  (SLO)
sli_cidr = "172.40.2.0/24"   # private subnet (SLI)

# ── EC2 ───────────────────────────────────────────────────────────────────────
# NOTE: If you change `region` above, you must also update `ami_id` to match.
# See the comment in variables.tf for a region → AMI lookup table.
ami_id        = "ami-08a006458983be57e"   # Amazon Linux 2, us-east-1
instance_type = "m5.2xlarge"
volume_size   = 80

# =============================================================================
# F5 XC CE Registration — fill these in before running terraform apply
# =============================================================================

# Paste the token from:
#   F5 XC Console → Multi-Cloud Network Connect → Manage →
#   Site Management → Site Tokens → Add Site Token
#
# SECURITY NOTE: Never commit this value to git.
# Add terraform.tfvars to your .gitignore file.
f5xc_registration_token = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

