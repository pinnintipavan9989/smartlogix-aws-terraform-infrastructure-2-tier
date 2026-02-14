module "network" {
  source         = "./modules/network"
  project_prefix = var.project_prefix
  env            = var.env
}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%^&*()-_=+[]{}<>?"
}

module "iam_operations_role" {
  source                    = "./modules/iam_operations_role"
  project_prefix            = var.project_prefix
  env                       = var.env
  admin_email               = var.admin_email
  backup_bucket_name        = var.backup_bucket_name
  ec2_instance_profile_name = var.ec2_instance_profile_name
}

module "db" {
  source                = "./modules/db"
  project_prefix        = var.project_prefix
  env                   = var.env
  vpc_id                = module.network.vpc_id
  private_subnet_ids    = module.network.private_subnet_ids
  api_security_group_id = module.compute_api.api_security_group_id
  db_username           = "smartlogix_admin"
  db_password           = random_password.db_password.result
}

module "compute_api" {
  source               = "./modules/compute_api"
  project_prefix       = var.project_prefix
  env                  = var.env
  vpc_id               = module.network.vpc_id
  ssh_cidr             = var.ssh_cidr
  CWA_DEB_URL          = var.CWA_DEB_URL
  public_subnet_id     = module.network.public_subnet_ids[0]
  api_instance_type    = var.api_instance_type
  db_endpoint          = module.db.db_endpoint
  db_username          = module.db.db_username
  db_password          = random_password.db_password.result
  iam_instance_profile = module.iam_operations_role.ec2_instance_profile_name
}

module "s3_backup" {
  source             = "./modules/s3_backup"
  project_prefix     = var.project_prefix
  env                = var.env
  backup_bucket_name = var.backup_bucket_name
}

module "monitoring" {
  source          = "./modules/monitoring"
  project_prefix  = var.project_prefix
  env             = var.env
  admin_email     = var.admin_email
  sns_name        = var.alerts_sns_name
  api_sg_id       = module.compute_api.api_security_group_id
  db_identifier   = module.db.db_identifier
  aws_region      = var.aws_region
  api_instance_id = module.compute_api.api_instance_id
}

module "automation_scripts" {
  source         = "./modules/automation_scripts"
  project_prefix = var.project_prefix
  env            = var.env
  backup_bucket  = module.s3_backup.backup_bucket_name
}

module "itsm_simulation" {
  source         = "./modules/itsm_simulation"
  project_prefix = var.project_prefix
  env            = var.env
  ticket_bucket  = module.s3_backup.backup_bucket_name
}
