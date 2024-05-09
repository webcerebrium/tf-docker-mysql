output "credentials" {
  value = ({
      host = local.host
      database = local.database
      user = local.user
      password = local.password
  })
  sensitive = true
  description = "credentials for the main database. Use this if databases are not specified"
}
