#!/bin/sh
### BEGIN INIT INFO
# Provides: gpclkconfig
# Required-Start:    $all
# Required-Stop: 
# Default-Start:     5 
# Default-Stop:      6 
# Short-Description: Your service description
### END INIT INFO

/usr/bin/minimal_clk 11.2896M -m 1 -q
