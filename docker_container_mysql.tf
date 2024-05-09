
resource "docker_container" "mysql" {
  count = var.disabled > 0 ? 0 : 1
  image = docker_image.mysql[0].image_id
  name = local.host
  restart = "always"
  log_opts = var.network_params.log_opts

  networks_advanced {
    name  = local.network_id
  }
  env = local.env
  command = local.command
  
  dynamic ports {
    for_each = local.ports
    content {
      internal = ports.value.internal
      external = ports.value.external
    }
  }

  dynamic "labels" {
    for_each = local.labels
    content {
      label = labels.value.label
      value = labels.value.value
    }
  }

  dynamic upload {
    for_each = local.upload
    content {
      file = upload.value.file
      content = upload.value.content
      executable = false
    }
  }

  dynamic mounts {
    for_each = concat([ local.mounted_exchange ], local.mounts)
    content {
      read_only = false
      source =mounts.value.source
      target = mounts.value.target
      type = "bind"
    }
  }
  
  dynamic volumes {
    for_each = local.volumes
    content {
      read_only = false
      container_path = volumes.value.container_path
      volume_name = volumes.value.volume_name
    }
  }

  network_mode = "bridge"
}
