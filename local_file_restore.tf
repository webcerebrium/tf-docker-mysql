resource "local_file" "restore" {
   count = var.disabled > 0 ? 0 : 1
   content = <<EOF
#!/usr/bin/env bash
set -ex

export DIR="$( cd "$( dirname "$${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/mysql-wait.sh
export DIR_EXCHANGE=${local.volume_exchange}
export REALM=${var.network_params.env != "prod" ? "backup-dev" : "backup-prod"}

cd $DIR_EXCHANGE
[[ "$DATABASES" == "" ]] && {
    export DATABASES="${var.databases != [] ? join(" ", var.databases) : local.database}"
}
for D in $DATABASES; do

    # from backup server, receive backup of database $D 
    ${var.backup_host == "" ? "" : join("\n", [
        "docker exec -it -v $DIR_EXCHANGE:/exchange/ ${var.backup_host} pull --name ${local.project}-mysql-$D"
    ])}
    export LATEST=$(ls -1  | grep ${local.project}-mysql-$D | sort | tail -n 1 | tr -d \'[:space:]\')
    echo $LATEST
    echo "Latest backup is available at $LATEST"

    # if $LATEST ends with .sql.gz
    [[ $LATEST == *.sql.gz ]] && {
        if [[ $(command -v unpigz) ]]; then
            unpigz --keep -d -f $LATEST
        else
            gunzip --keep -d -f $LATEST
        fi
    }
    # LAST_SQL is the uncompressed sql file name, without .gz extension
    export LAST_SQL=$(echo $LATEST | sed 's/.gz//') 
    
    docker exec -it -e MYSQL_DATABASE=$D ${local.host} \
        bash -c 'mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE -e "\. /exchange/'$LAST_SQL'"'
    
    rm -f $DIR_EXCHANGE/$LAST_SQL
done

EOF
   filename = "./bin/mysql-restore.sh"
   file_permission = "0777"
}
