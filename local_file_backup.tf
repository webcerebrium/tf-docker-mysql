resource "local_file" "backup" {
   count = var.disabled > 0 ? 0 : 1
   content = <<EOF
#!/usr/bin/env bash
set -ex
export DIR="$( cd "$( dirname "$${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export DIR_EXCHANGE=${local.volume_exchange}
export REALM=${var.network_params.env != "prod" ? "backup-dev" : "backup-prod"}

now() {
    date +"%Y%m%dT%H%M%S"
}

[[ "$DATABASES" == "" ]] && {
    export DATABASES="${var.databases != [] ? join(" ", var.databases) : local.database}"
}
for D in $DATABASES; do
    cd $DIR_EXCHANGE
    export LAST_SQL=${local.project}-mysql-$D-`now`-${var.network_params.env}.sql
    export LAST_SQL_GZ=$LAST_SQL.gz
    echo "Starting MySQL backup"
    docker exec -i -e MYSQL_DATABASE=$D ${local.host} bash -c 'mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > /exchange/'$LAST_SQL''
    if [[ $(command -v pigz) ]]; then
        pigz -f $DIR_EXCHANGE/$LAST_SQL
    else
        gzip -f $DIR_EXCHANGE/$LAST_SQL
    fi
    echo "Created as $LAST_SQL_GZ"
    ls -All $DIR_EXCHANGE/$LAST_SQL_GZ
    chmod -R 0777 $DIR_EXCHANGE/$LAST_SQL_GZ

    ${var.backup_host == "" ? "" : join("\n", [
        "docker exec -i -v $DIR_EXCHANGE:/exchange/ ${var.backup_host} push --clean --name ${local.project}-mysql-$D --file $LAST_SQL_GZ"
    ])}
done

EOF
   filename = "./bin/mysql-backup.sh"
   file_permission = "0777"
}
