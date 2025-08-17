
output "sql_instance_connection_name" {
  description = "The connection name of the SQL instance."
  value       = google_sql_database_instance.main.connection_name
}
