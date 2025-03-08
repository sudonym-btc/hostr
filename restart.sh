#!/bin/bash
./stop.sh && rm -rf ./docker/data && ./start.sh && ./setup.sh
# NEeed to remove boltz data folder and insert the clean version and update permissions to make runnable
