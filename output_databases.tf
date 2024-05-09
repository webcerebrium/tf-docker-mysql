output "databases" {
  value = local.credentials
  sensitive = true
  description = "credentials for each additional database"
}
