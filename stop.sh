#!/bin/bash
(cd ./docker/boltz && ./stop.sh) && docker-compose down --volumes
