resource "local_file" "crontab_mysql" {
  count = var.disabled > 0 ? 0 : 1
  content = "1 3 * * * cd ${path.cwd} && ./bin/mysql-backup.sh >> /var/log/mysql-backup.log 2>&1"

  filename = "./cron.d/crontab_mysql"
  file_permission = "0777"
}
