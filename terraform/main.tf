# =============================================================================
# main.tf — F5 SMSv2 CE Infrastructure on AWS
#
# This file provisions everything the two shell scripts did, in order:
#   1. VPC (with DNS enabled)
#   2. Public subnet (SLO) + Private subnet (SLI)
#   3. Internet Gateway + Route Table → attached to SLO subnet
#   4. Security Group with all required F5 CE rules
#   5. SSH Key Pair (auto-generated, saved as a local .pem file)
#   6. Elastic IP
#   7. Network Interface (on the SLO subnet)
#   8. EC2 Instance (using the ENI above, with encrypted gp3 volume)
#   9. Elastic IP Association → bound to the ENI
# =============================================================================

terraform {
  required_version = ">= 1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
    tls = {
      # Used to generate the SSH private key
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      # Used to write the .pem file to disk
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Tell Terraform which AWS region to deploy into
provider "aws" {
    region = var.region
}

# =============================================================================
# 1. VPC
# =============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true   # allows EC2 instances to get public DNS names
  enable_dns_support   = true

  tags = {
    Name    = "${var.project}-f5-ce-vpc"
    Project = var.project
  }
}

# =============================================================================
# 2. Subnets
# =============================================================================

# SLO = "Site Local Outside" — public subnet, Internet-facing
resource "aws_subnet" "slo" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.slo_cidr

  tags = {
    Name    = "${var.project}-slo"
    Project = var.project
  }
}

# SLI = "Site Local Inside" — private subnet, internal traffic only
resource "aws_subnet" "sli" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.sli_cidr

  tags = {
    Name    = "${var.project}-sli"
    Project = var.project
  }
}

# =============================================================================
# 3. Internet Gateway + Route Table
# =============================================================================

# The Internet Gateway is what allows the VPC to communicate with the Internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-f5-ce-igw"
    Project = var.project
  }
}

# A route table tells the subnet where to send traffic.
# This one sends all Internet-bound traffic (0.0.0.0/0) to the IGW.
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "${var.project}-f5-ce-rt"
    Project = var.project
  }
}

# Attach the route table to the SLO (public) subnet only.
# The SLI (private) subnet deliberately has no route to the Internet.
resource "aws_route_table_association" "slo" {
  subnet_id      = aws_subnet.slo.id
  route_table_id = aws_route_table.main.id
}

# =============================================================================
# 4. Security Group
# =============================================================================

resource "aws_security_group" "f5_ce" {
  name        = "${var.project}-f5-ce-sg"
  description = "F5 Distributed Cloud CE Security Group"
  vpc_id      = aws_vpc.main.id

  # ICMP — allows ping and other diagnostic traffic
  ingress {
    description = "ICMP all"
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  # TCP — all ports (SSH, HTTPS, management, etc.)
  ingress {
    description = "TCP all ports"
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

  # UDP 500 — IKE/ISAKMP (IPsec key negotiation)
  ingress {
    description = "IKE/ISAKMP"
    protocol    = "udp"
    from_port   = 500
    to_port     = 500
    cidr_blocks = ["0.0.0.0/0"]
  }

  # UDP 4500 — IKE NAT Traversal (IPsec through NAT devices)
  ingress {
    description = "IKE NAT-T"
    protocol    = "udp"
    from_port   = 4500
    to_port     = 4500
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Protocol 50 — ESP (Encapsulating Security Payload, used by F5 XC Site Mesh)
  # from_port / to_port must be -1 for non-TCP/UDP protocols
  ingress {
    description = "ESP (IPsec) - F5 XC Site Mesh"
    protocol    = "50"
    from_port   = -1
    to_port     = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic (required for the instance to communicate out)
  egress {
    description = "Allow all outbound"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-f5-ce-sg"
    Project = var.project
  }
}

# =============================================================================
# 5. SSH Key Pair
# =============================================================================

# Generate a fresh RSA key pair (Terraform does this automatically)
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register the public half with AWS so EC2 can inject it into the instance
resource "aws_key_pair" "main" {
  key_name   = "${var.project}-f5-key"
  public_key = tls_private_key.ssh.public_key_openssh

  tags = {
    Name    = "${var.project}-f5-key"
    Project = var.project
  }
}

# Save the private key locally as a .pem file (chmod 400 = owner read-only)
resource "local_sensitive_file" "ssh_key_pem" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/${var.project}-f5-key.pem"
  file_permission = "0400"
}

# =============================================================================
# 6. Elastic IP
# =============================================================================

# An Elastic IP is a static public IP address that stays the same even if the
# instance is stopped and started. It gets associated to the ENI below.
resource "aws_eip" "f5_ce" {
  domain = "vpc"

  tags = {
    Name    = "${var.project}-f5-ce-eip"
    Project = var.project
  }
}

# =============================================================================
# 7. Network Interface (ENI)
# =============================================================================

# An explicit ENI (Elastic Network Interface) is created on the SLO subnet.
# Attaching the instance to a pre-created ENI (rather than a bare subnet) means
# the Elastic IP can be moved independently of the instance if needed.
resource "aws_network_interface" "f5_ce" {
  subnet_id       = aws_subnet.slo.id
  description     = "${var.project} F5-CE primary interface (SLO)"
  security_groups = [aws_security_group.f5_ce.id]

  tags = {
    Name    = "${var.project}-f5-ce-eni"
    Project = var.project
  }
}

# =============================================================================
# 8. EC2 Instance
# =============================================================================

resource "aws_instance" "f5_ce" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.main.key_name

# ── Cloud-init / Registration ──────────────────────────────────────────────
  # `user_data` is the mechanism AWS uses to pass bootstrap instructions to an
  # EC2 instance on its very first boot. We pass the rendered cloud-init YAML
  # from cloud_init.tf, which writes /etc/vpm/user_data with the F5 XC token.
  #
  # The F5 VPM daemon reads that file automatically after cloud-init finishes
  # and uses the token to register this node with the F5 XC control plane.
  #
  # user_data_replace_on_change = true means: if you change the token or any
  # cloud-init value, Terraform will replace (re-create) the instance so it
  # boots fresh with the updated user_data. Without this, changes to user_data
  # are ignored on a running instance (AWS doesn't re-run cloud-init).
  user_data                   = local.f5_ce_user_data
  user_data_replace_on_change = true

  
  # Attach the ENI we created above as the primary network interface (device 0)
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.f5_ce.id
  }

  # Root EBS volume — encrypted gp3, deleted when the instance is terminated
  root_block_device {
    volume_size           = var.volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name    = "${var.project}-f5-ce-vol"
      Project = var.project
    }
  }

  # IMDSv2 — forces the instance metadata service to use session-oriented tokens,
  # which is more secure than the legacy IMDSv1.
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    http_endpoint               = "enabled"
  }

  tags = {
    Name    = "${var.project}-f5-ce-node"
    Project = var.project
    Role    = "f5-ce"
  }
}

# =============================================================================
# 9. Associate Elastic IP to the Network Interface
# =============================================================================

resource "aws_eip_association" "f5_ce" {
  allocation_id        = aws_eip.f5_ce.id
  network_interface_id = aws_network_interface.f5_ce.id
}