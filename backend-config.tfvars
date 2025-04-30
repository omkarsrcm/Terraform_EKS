    bucket = "hfnlife-dev"
    key    = "terraform_state/hfnlife-dev.tfstate"
    region = "ap-south-1"
    encrypt      = true  
    use_lockfile = true  #S3 native locking
    assume_role = {
      role_arn = "arn:aws:iam::AccountID:role/terraform-executor-role"
    }