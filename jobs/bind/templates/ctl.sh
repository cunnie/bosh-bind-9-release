#!/bin/bash

# named logs to syslog, daemon facility
# BOSH captures these in /var/log/daemon.log
RUN_DIR=/var/vcap/sys/run/named
PIDFILE=${RUN_DIR}/pid

case $1 in

  start)
    # ugly way to install libjson.0 shared library dependency
    if [ -f /etc/redhat-release ]; then
      # Install libjson0 for CentOS stemcells.
      # We first check if it's installed to prevent an
      # an over-eager yum from contacting the Internet.
      rpm -qi json-c > /dev/null || yum install -y libjson.0
    elif [ -f /etc/lsb-release ]; then
      # install libjson0 for Ubuntu stemcells (not tested)
      apt-get install libjson0
    fi

    mkdir -p $RUN_DIR
    chown -R vcap:vcap $RUN_DIR

    echo $$ >> $PIDFILE

    exec /var/vcap/packages/bind-9-9.10.2/sbin/named -u vcap -c /var/vcap/jobs/bind/etc/named.conf

    ;;

  stop)

    PID=$(cat $PIDFILE)
    if [ -n $PID ]; then
      SIGNAL=0
      N=1
      while kill -$SIGNAL $PID 2>/dev/null; do
        if [ $N -eq 1 ]; then
          echo "waiting for pid $PID to die"
        fi
        if [ $N -eq 11 ]; then
          echo "giving up on pid $PID with kill -0; trying -9"
          SIGNAL=9
        fi
        if [ $N -gt 20 ]; then
          echo "giving up on pid $PID"
          break
        fi
        n=$(($N+1))
        sleep 1
      done
    fi

    rm -f $PIDFILE

    ;;

  *)
    echo "Usage: ctl {start|stop}" ;;

esac
