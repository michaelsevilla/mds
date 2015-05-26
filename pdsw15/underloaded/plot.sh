#!/bin/bash

tailplot latencies.dat -x 1 --field-format=1,date,HH:mm:ss --x-format=date,HH:mm:ss -s 3,4 -f latency,avg reqs.dat -x 1 --field-format=1,date,HH:mm:ss --x-format=date,HH:mm:ss -s 2 --y2=2 -f num-requests &
