#!/bin/bash
echo "Welcome to the Encoding/Remux Container"
echo "1) Launch Yuuno (JupyterLab)"
echo "2) Launch MKVToolNix GUI"
echo "3) Exit"

read -p "Choose an option: " opt
case $opt in
    1)
        jupyter lab --allow-root --port=8888 --no-browser --ip=0.0.0.0
        ;;
    2)
        mkvtoolnix-gui
        ;;
    *)
        echo "Exiting..."
        ;;
esac