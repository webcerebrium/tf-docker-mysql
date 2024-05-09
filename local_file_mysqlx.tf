resource "local_file" "mysqlx" {
   count = var.disabled > 0 ? 0 : 1
   content = <<EOF
#!/usr/bin/env bash

export DIR="$( cd "$( dirname "$${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[[ $DB == "" ]] && {
    export DB="${local.database}"
}

export DATABASE_URL="mysql://root:${local.password}@${local.host}:3306/$DB"
cd $DIR/../../../

[ ! -d "$(pwd)/migrations/mysql/$DB" ] && {
    echo "Folder does not exist: $(pwd)/migrations/mysql/$DB";
    exit 1
}

docker run --name sqlx-mysql-cli --network=${local.network_id} --rm -it \
    -v $(pwd)/migrations/mysql/$DB:/app/migrations \
    -w /app \
    -e DATABASE_URL=$DATABASE_URL \
    wcrbrm/sqlx-mysql $@

if [[ $1 == "migrate" ]]; then
  if [[ $2 == "add" ]]; then
 	sudo chown -R `whoami`:`whoami` $(pwd)/migrations/mysql/$DB
  fi
fi
EOF
   filename = "./bin/mysqlx.sh"
   file_permission = "0777"
}

