#!/bin/bash

rm -r /etc/frr/frr.conf
cp  /etc/hicn/frr.conf /etc/frr/frr.conf
bash /etc/hicn/init.sh

