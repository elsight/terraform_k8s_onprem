account_id  = "930579047961"
environment = "dev"

instance_configs = {
  "Daniel-onprem-k8s" = {
    instance_type   = "t3.xlarge"
    enable_s3_mount = true
  },
  "Gal-onprem-k8s" = {
    instance_type = "t3.xlarge"
  },
  "Itamar-onprem-k8s" = {
    instance_type = "t3.xlarge"
  },
  "Prabin-onprem-k8s" = {
    instance_type = "t3.xlarge"
  },
  "test_offline-onprem-k8s" = {
    instance_type = "t3.xlarge"
  },


}

# S3 mount configuration (applies to instances with enable_s3_mount = true)
s3_mount_point               = "/mnt/s3-versions"
s3_mount_readonly            = false  # Enable read-write access
s3_mount_allow_delete        = false  # Disable delete operations
