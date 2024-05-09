resource "docker_image" "mysql_exporter" {
  name = "bitnami/mysqld-exporter"
  count = var.enable_metrics ? 1 : 0
  keep_locally = true
}
