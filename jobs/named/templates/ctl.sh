#!/bin/bash

# named logs to syslog, daemon facility
# BOSH captures these in /var/log/daemon.log
RUN_DIR=/var/vcap/sys/run/named
# PIDFILE is created by named, not by this script
PIDFILE=${RUN_DIR}/named.pid

case $1 in

  start)
    # ugly way to install libjson.0 shared library dependency
    if [ -f /etc/redhat-release ]; then
      # Install libjson0 for CentOS stemcells.
      # We first check if it's installed to prevent an
      # an over-eager yum from contacting the Internet.
      rpm -qi json-c > /dev/null || yum install -y json-c
    elif [ -f /etc/lsb-release ]; then
      # install libjson0 for Ubuntu stemcells (not tested)
      apt-get install libjson0
    fi

    mkdir -p $RUN_DIR
    chown -R vcap:vcap $RUN_DIR

    exec /var/vcap/packages/bind-9-9.10.2/sbin/named -u vcap -c /var/vcap/jobs/named/etc/named.conf

    ;;

  stop)

    PID=$(cat $PIDFILE)
    if [ -n $PID ]; then
      SIGNAL=TERM
      N=1
      while kill -$SIGNAL $PID 2>/dev/null; do
        if [ $N -eq 1 ]; then
          echo "waiting for pid $PID to die"
        fi
        if [ $N -eq 11 ]; then
          echo "giving up on pid $PID with kill -TERM; trying -KILL"
          SIGNAL=KILL
        fi
        if [ $N -gt 20 ]; then
          echo "giving up on pid $PID"
          break
        fi
        N=$(($N+1))
        sleep 1
      done
    fi

    rm -f $PIDFILE

    ;;

  *)
    echo "Usage: ctl {start|stop}" ;;

esac
