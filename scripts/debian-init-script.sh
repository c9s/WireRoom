#!/bin/bash
### BEGIN INIT INFO
# Provides:          redmine
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts wireroom
# Description:       starts wireroom
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin


NAME=wireroom
PIDFILE=/var/run/$NAME.pid
SERVER=Twiggy
PLACK_BIN=/usr/local/bin/plackup
APP_DIR=/home/wireroom/WireRoom
DAEMON=/usr/local/bin/start_server
PORT=3001

USER=c9s
GROUP=admin

test -x $DAEMON || exit 0

set -e

function start_app()
{
    start-stop-daemon --user $USER --group $GROUP --background --start --chdir $APP_DIR \
        --exec $DAEMON -- --pid-file=$PIDFILE --port $PORT \
            -- $PLACK_BIN -s $SERVER -E production app.psgi
}

function stop_app()
{
    start-stop-daemon --stop --pidfile $PIDFILE --retry 5
    rm -f $PIDFILE
}
 
case "$1" in
  start)
        echo "Starting $NAME: "
        start_app
        echo "[Done]"
        ;;
  stop)
        echo "Stopping $NAME: "
        stop_app
        echo "[Done]"
        ;;
  restart)
        echo "Stopping $NAME: "
        stop_app
        echo "[Done]"

        echo "Starting $NAME: "
        start_app
        echo "[Done]"
        ;;
  *)
        echo "Usage: /etc/init.d/$NAME {start|stop|restart}" >&2
        exit 1
        ;;
esac
 
exit 0
