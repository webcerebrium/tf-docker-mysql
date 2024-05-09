locals {
  network_id = var.network_params.network_id
  project    = var.network_params.project
  postfix    = var.network_params.postfix

  volume_exchange  = var.volume_exchange
  
  host          = "mysql-${var.network_params.postfix}"
  port          = "3306"
  user          = "${var.network_params.project}${var.network_params.postfix}"
  password      = random_string.password.result
  root_password = random_string.root_password.result
  database      = "${var.network_params.project}${var.network_params.postfix}"
}

locals {
  env = [
    "MYSQL_ROOT_PASSWORD=${local.root_password}",
    "MYSQL_DATABASE=${local.database}",
    "MYSQL_USER=${local.user}",
    "MYSQL_PASSWORD=${local.password}",
  ]

  init_exporter_sql = join("\n",[
    "GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO '${local.user}'@'%';"
  ])

  init_sql = join("\n", [for d in var.databases : 
    "CREATE DATABASE IF NOT EXISTS ${d};\nGRANT ALL PRIVILEGES ON ${d}.* TO '${local.user}'@'%';\n"
  ]) 

  command = [
    "mysqld",
    "--character-set-server=utf8mb4",
    "--secure_file_priv=/exchange",
    "--collation-server=utf8mb4_unicode_ci",
    // "--default-authentication-plugin=mysql_native_password",
    "--sql_mode=${var.sql_mode}"
  ]

  upload = [{
    content = join("\n", concat([ local.init_sql, "\n", local.init_exporter_sql ]))
    file = "/docker-entrypoint-initdb.d/init.sql"
  }]

  mounted_exchange = {
    source = local.volume_exchange
    target = "/exchange"
  }

  mounts = var.disabled > 0 || var.mounted == "" ? [] : [
    {
      source = var.mounted
      target = "/var/lib/mysql"
    }
  ]

  volumes = var.disabled > 0 || local.mounts != [] ? [] : [{
    container_path = "/var/lib/mysql"
    volume_name    = docker_volume.storage[0].name
  }]

  ports = var.open_ports ? [{
    internal = 3306
    external = 3306
  }] : []

  credentials = {for d in var.databases: 
    d => {
      database = d
      host     = local.host
      port     = local.port
      user     = local.user
      password = local.password
    }
  }

  labels = concat(var.network_params.labels, [
    {
      label = "host",
      value = local.host
    },
    {
      label = "role"
      value = "mysql"
    }
  ])
}
