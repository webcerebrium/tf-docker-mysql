resource "docker_volume" "storage" {
  count = var.disabled > 0 || var.mounted != "" ? 0 : 1
  name  = "${local.project}-mysql-storage-${local.postfix}"
}
