resource "local_file" "wait" {
   count = var.disabled > 0 ? 0 : 1
   content = <<EOF
#!/usr/bin/env bash
set -e
export PID=$(docker ps --filter "label=host=${local.host}" --format "{{.ID}}")
   
out() { echo [`date`] $@; }
react_on_status() {
  local RESPONSE=$(docker exec $PID bash -c 'mysqladmin ping -u root -p$MYSQL_ROOT_PASSWORD')
  if [[ "$RESPONSE" == *"mysqld is alive"* ]]; then
    echo "READY"
  fi
}

if [[ "$PID" != "" ]]; then
    export COUNTER=30
    export DELAY=10
    export SERVICE="MYSQL"

    out "Waiting for $SERVICE... May take 1 min. ($COUNTER)"
    until [[ "$(react_on_status)" != "" ]]
    do
        COUNTER=$((COUNTER - 1))
        if [ "$COUNTER" == "0" ]; then
            die "$HOST waiting timeout. $SERVICE was not ready."
        fi
        sleep "$DELAY"
        out "Waiting for $SERVICE... May take 1 min. ($COUNTER)"
    done
    out "ALIVE"
else 
   out "ERROR: mysql docker process was not found"
   exit 1
fi
EOF

   filename = "./bin/mysql-wait.sh"
   file_permission = "0777"
}
