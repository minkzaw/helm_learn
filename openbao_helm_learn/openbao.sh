#!/bin/sh

sealFile=/tmp/openbao_seal.txt
#sealFile=./openbao_seal.txt

# For initializing OpenBAO at startup
init_bao() {
    bao operator init > "${sealFile}"
    bao login $(grep "Initial Root Token" "${sealFile}" | cut -d ":" -f 2)
}

unseal_bao() {
    # Create a variable to hold unseal keys
    unseal_keys=""
    key_count=0

    # Loop through the keys from the sealFile
    while IFS= read -r line; do
        key=$(echo "${line}" | grep "Unseal Key" | cut -d ":" -f 2 | xargs)
        if [ -n "$key" ]; then
            unseal_keys="$unseal_keys$key "
            key_count=$((key_count + 1))
        fi
    done < "${sealFile}"

    # Split keys and unseal with the first three
    count=0
    for key in $unseal_keys; do
        if [ $count -lt 3 ]; then
            echo "$key"
            bao operator unseal "$key"
            echo ""
            count=$((count + 1))
        fi
    done

    echo "========Seale Status========"
    bao status | grep "Sealed"
}

# Check if an argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 {init|unseal}"
    exit 1
fi

# Handle user input from the command line argument
case "$1" in
    init)
        init_bao
        unseal_bao
        ;;
    unseal)
        if [ -f "${sealFile}" ]; then
            unseal_bao
        else
            echo "Seal file not found. Please initialize first."
        fi
        ;;
    *)
        echo "Invalid option. Please use 'init' or 'unseal'."
        exit 1
        ;;
esac