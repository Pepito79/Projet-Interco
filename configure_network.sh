#!/bin/bash
echo "Starting All Components Configuration..."
for s in scripts/*.sh; do
    echo "Running $s..."
    ./$s
done
echo "All configured."
