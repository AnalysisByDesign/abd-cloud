# --------------------------------------------------------------------------------------------
# Aurora Cluster
# --------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# --------------------------------------------------------------------------------------------

variable "name" {
  description = "The name of the RDS instance"
  type        = string
}

variable "admin_password" {
  description = "The password of the admin user account"
  type        = string
}

# --------------------------------------------------------------------------------------------
# CLUSTER OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# --------------------------------------------------------------------------------------------

variable "r53_name" {
  description = "The name for the route53 entry"
  type        = string
  default     = ""
}

variable "engine" {
  description = "The DB engine"
  type        = string
  default     = "mysql"
}

variable "engine_version" {
  description = "The DB engine version"
  type        = string
  default     = "5.7.26"
}

variable "port" {
  description = "Connection port"
  type        = string
  default     = "3306"
}

# The VPC name is automatically prepended to this input variable
variable "subnet_group_name" {
  description = "The DB subnet group name"
  type        = string
  default     = "rds"
}

# The VPC name is automatically prepended to this input variable
variable "param_group_name" {
  description = "The DB parameter group name"
  type        = string
  default     = "rds"
}

variable "cloudwatch_logging" {
  description = "List of cloudwatch logging options"
  type        = list(string)
  default     = ["audit", "error", "slowquery"]
}

variable "azs" {
  description = "Availability zones to launch instances into"
  type        = list(string)
  default     = []
}

variable "security_groups" {
  description = "Security groups for instances"
  type        = list(string)
  default     = []
}

variable "admin_name" {
  description = "The name of the admin user account"
  type        = string
  default     = "admin"
}

variable "schema_name" {
  description = "The name of the initial schema to create if required"
  type        = string
  default     = ""
}

variable "storage_encrypted" {
  description = "Encrypt the RDS storage at rest"
  default     = true
}

variable "storage_type" {
  description = "The type of storage to be used"
  type        = string
  default     = "gp2"
}

variable "allocated_storage" {
  description = "The amount of storage allocated to the instance"
  type        = string
  default     = "20"
}

variable "kms_key_id" {
  description = "KMS key id to use when encrypting storage"
  type        = string
  default     = ""
}

variable "iam_roles" {
  description = "List of IAM roles to associate with the cluster"
  type        = list(string)
  default     = []
}

variable "iam_authentication_enabled" {
  description = "Enable IAM authentication for applications"
  default     = false
}

variable "snapshot_identifier" {
  description = "Name of snapshot to create cluster from"
  type        = string
  default     = ""
}

variable "build_from_latest_snapshot" {
  description = "Create the cluster from the latest snapshot"
  default     = true
}

variable "skip_final_snapshot" {
  description = "Do not create a final snapshot on termination"
  default     = true
}

variable "final_snapshot_identifier" {
  description = "Name of final snapshot identifier to create if required"
  type        = string
  default     = ""
}

variable "backup_retention" {
  description = "How many days of automated backups to retain"
  type        = string
  default     = "1"
}

variable "backup_window" {
  description = "When to run automated snapshots"
  type        = string
  default     = "02:00-02:30"
}

variable "maintenance_window" {
  description = "When to run default maintenance tasks"
  type        = string
  default     = "sun:03:00-sun:03:30"
}

variable "apply_immediately" {
  description = "Create a final snapshot on termination"
  default     = false
}

variable "rds_tags" {
  description = "A map of RDS tags to add to all resources"
  type        = map(string)

  default = {
    "Component" = "rds aurora"
  }
}

variable "instance_class" {
  description = "The instance class for the instances"
  type        = string
  default     = "db.t3.micro"
}

variable "monitoring_interval" {
  description = "The enhanced monitoring metric collection interval"
  type        = string
  default     = "60"
}

variable "performance_insights_enabled" {
  description = "Enable performance insight data collection"
  default     = false
}

variable "performance_insights_kms_key_id" {
  description = "KMS key to encrypt performance insight data"
  type        = string
  default     = ""
}
