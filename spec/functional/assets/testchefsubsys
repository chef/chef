#!/bin/bash
# trapchild

sleep 120 &

pid="$!"

trap 'echo I am going down, so killing off my processes..; kill $pid; exit' SIGHUP SIGINT SIGQUIT SIGTERM

wait
