#!/bin/bash

#accorder les permissions 
find . -name "*.sh" -exec chmod +x {} \;

echo "Starting All Components Configuration..."
for s in scripts/*.sh; do
    echo "Running $s..."
    ./$s
done
echo "All configured."
