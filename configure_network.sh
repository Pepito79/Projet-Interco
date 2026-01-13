#!/bin/bash

#accorder les permissions 
find . -name "*.sh" -exec chmod +x {} \;

echo "Starting All Components Configuration..."
echo "Starting All Components Configuration..."

# 1. CORE ROUTERS (Must be UP first for Internet Access)
for s in scripts/R*.sh; do
    echo "Running $s..."
    ./$s
done

# 2. OTHER SCRIPTS (Clients, Servers, DNS, etc.)
for s in scripts/*.sh; do
    # Skip R* scripts as they are already run
    [[ $s == scripts/R* ]] && continue
    echo "Running $s..."
    ./$s
done
echo "All configured."
