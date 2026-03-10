# =============================================================================
# cloud_init.tf — Renders the cloud-init user_data for the F5 CE node
#
# How it works:
#   1. `templatefile()` reads user_data.tpl and substitutes every ${...}
#      placeholder with the matching variable value from terraform.tfvars.
#   2. The resulting YAML string is stored in `local.f5_ce_user_data`.
#   3. main.tf passes that string to the EC2 instance's `user_data` argument.
#   4. AWS sends it to the instance at boot via the instance metadata service.
#   5. cloud-init runs on first boot, writes /etc/vpm/user_data, and the
#      F5 VPM daemon picks it up to register the node with F5 XC.
#
# What is cloud-init?
#   cloud-init is a standard tool that runs on Linux VMs the very first time
#   they boot. It can create files, run scripts, install packages, etc.
#   AWS supports it natively — whatever you put in `user_data` is handed to
#   cloud-init automatically.
# =============================================================================

locals {
  f5_ce_user_data = templatefile("${path.module}/user_data.tpl", {
    f5xc_registration_token = var.f5xc_registration_token
    #f5xc_cluster_name       = var.f5xc_cluster_name
    #f5xc_certified_hardware = var.f5xc_certified_hardware
    #f5xc_latitude           = var.f5xc_latitude
    #f5xc_longitude          = var.f5xc_longitude
  })
}