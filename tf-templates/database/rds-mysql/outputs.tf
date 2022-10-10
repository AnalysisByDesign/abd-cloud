# --------------------------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------------------------

# RDS instance
output "rds_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.rds.arn
}

output "rds_id" {
  description = "The id of the RDS instance"
  value       = aws_db_instance.rds.id
}

output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.rds.address
}

output "rds_reader_endpoint" {
  description = "The reader_endpoint of the RDS instance"
  value       = aws_db_instance.rds.address
}

output "rds_hosted_zone_id" {
  description = "The hosted_zone_id of the RDS instance"
  value       = aws_db_instance.rds.hosted_zone_id
}
