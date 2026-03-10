#!/bin/sh
set -e

cd /workspace/escrow
exec dart run bin/cli.dart "$@"
