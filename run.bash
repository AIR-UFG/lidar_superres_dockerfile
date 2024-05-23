#!/bin/bash

# Set your Windows host IP here (replace with your actual IP address)
HOST_IP=172.23.128.1

# This uses the host IP and sets the display variable for X11 forwarding
DISPLAY=$HOST_IP:0.0

# Run the Docker container with X11 forwarding
docker run -it --rm --name super_res_ros1 \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $HOME/.Xauthority:/root/.Xauthority:ro \
  -e XAUTHORITY=/root/.Xauthority \
  super_res_ros
