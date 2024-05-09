resource "docker_image" "mysql" {
  name = "mysql:8"
  count = var.disabled > 0 ? 0 : 1
  keep_locally = true
}