resource "local_file" "shell" {
   count = var.disabled > 0 ? 0 : 1
   content = <<EOF
#!/usr/bin/env bash
set -x
[[ "$DB" == "" ]] && {
  export DB=${local.database}
}
export PID=$(docker ps --filter "label=host=${local.host}" --format "{{.ID}}")
if [[ "$PID" != "" ]]; then
  docker exec -it $PID bash -c 'mysqladmin ping -u root -p$MYSQL_ROOT_PASSWORD'
  docker exec -it $PID bash -c 'mysql -u root -p$MYSQL_ROOT_PASSWORD -e "show databases"'
  docker exec -it -e MYSQL_DATABASE=$DB $PID bash -c 'mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE'
else 
  echo "ERROR: mysql docker process was not found"
  exit 1
fi
EOF
   filename = "./bin/mysql-shell.sh"
   file_permission = "0777"
}
