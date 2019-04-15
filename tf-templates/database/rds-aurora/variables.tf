# --------------------------------------------------------------------------------------------
# Aurora Cluster
# --------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# --------------------------------------------------------------------------------------------

variable "name" {
  description = "The name of the Aurora Cluster"
  type        = "string"
}

variable "admin_password" {
  description = "The password of the admin user account"
  type        = "string"
}

# --------------------------------------------------------------------------------------------
# CLUSTER OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# --------------------------------------------------------------------------------------------

variable "r53_name" {
  description = "The name for the route53 entry"
  type        = "string"
  default     = ""
}

variable "engine" {
  description = "The Aurora engine"
  type        = "string"
  default     = "aurora-mysql"
}

variable "engine_version" {
  description = "The Aurora engine version"
  type        = "string"
  default     = "5.7.12"
}

variable "engine_mode" {
  description = "The Aurora engine mode (provisioned or serverless)"
  type        = "string"
  default     = "serverless"
}

variable "scaling_configuration" {
  description = "RDS Aurora Serverless scaling configuration"
  type        = "map"

  default = {
    auto_pause               = true
    max_capacity             = 4
    min_capacity             = 2
    seconds_until_auto_pause = 300
  }
}

variable "port" {
  description = "Connection port"
  type        = "string"
  default     = "3306"
}

# The VPC name is automatically prepended to this input variable
variable "subnet_group_name" {
  description = "The db subnet group name"
  type        = "string"
  default     = "rds-aurora"
}

# The VPC name is automatically prepended to this input variable
variable "param_group_name" {
  description = "The cluster parameter group name"
  type        = "string"
  default     = "rds-aurora"
}

variable "cloudwatch_logging" {
  description = "List of cloudwatch logging options"
  type        = "list"
  default     = ["audit", "error", "slowquery"]
}

variable "azs" {
  description = "Availability zones to launch instances into"
  type        = "list"
  default     = []
}

variable "security_groups" {
  description = "Security groups for instances"
  type        = "list"
  default     = []
}

variable "admin_name" {
  description = "The name of the admin user account"
  type        = "string"
  default     = "admin"
}

variable "schema_name" {
  description = "The name of the initial schema to create if required"
  type        = "string"
  default     = ""
}

variable "storage_encrypted" {
  description = "Encrypt the RDS storage at rest"
  default     = true
}

variable "kms_key_id" {
  description = "KMS key id to use when encrypting storage"
  type        = "string"
  default     = ""
}

variable "iam_roles" {
  description = "List of IAM roles to associate with the cluster"
  type        = "list"
  default     = []
}

variable "iam_authentication_enabled" {
  description = "Enable IAM authentication for applications"
  default     = false
}

variable "snapshot_identifier" {
  description = "Name of snapshot to create cluster from"
  type        = "string"
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
  type        = "string"
  default     = ""
}

variable "backtrack_window" {
  description = "The backtrack window in seconds"
  type        = "string"
  default     = "0"
}

variable "backup_retention" {
  description = "How many days of automated backups to retain"
  type        = "string"
  default     = "1"
}

variable "backup_window" {
  description = "When to run automated snapshots"
  type        = "string"
  default     = "02:00-02:30"
}

variable "maintenance_window" {
  description = "When to run default maintenance tasks"
  type        = "string"
  default     = "sun:03:00-sun:03:30"
}

variable "apply_immediately" {
  description = "Create a final snapshot on termination"
  default     = false
}

variable "rds_tags" {
  description = "A map of RDS tags to add to all resources"
  type        = "map"

  default = {
    "Component" = "rds aurora"
  }
}

# --------------------------------------------------------------------------------------------
# INSTANCE OPTIONAL PARAMETERS
# You must provide a value for each of these parameters.
# --------------------------------------------------------------------------------------------

variable "read_replica_count" {
  description = "The number of read replica instances to create"
  type        = "string"
  default     = "0"
}

variable "instance_class" {
  description = "The instance class for the instances"
  type        = "string"
  default     = "db.t2.small"
}

variable "monitoring_interval" {
  description = "The enhanced monitoring metric collection interval"
  type        = "string"
  default     = "60"
}

variable "performance_insights_enabled" {
  description = "Enable performance insight data collection"
  default     = false
}

variable "performance_insights_kms_key_id" {
  description = "KMS key to encrypt performance insight data"
  type        = "string"
  default     = ""
}
