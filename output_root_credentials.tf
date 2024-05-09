output "root_credentials" {
  value = ({
      host = local.host
      database = local.database
      user = "root"
      password = local.root_password
  })
  sensitive = true
}
