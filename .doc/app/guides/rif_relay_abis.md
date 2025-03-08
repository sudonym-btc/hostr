git clone git@github.com:rsksmart/rif-relay-contracts.git
(
    cd rif-relay-contracts && npm install
)
cp ./rif-relay-contracts/artifacts/contracts/**/* ./app/lib/data/sources/rif_relay/contracts
find ./app/lib/data/sources/rif_relay/contracts -type f -name '*.dbg.*' -delete
(
    cd ./app/lib/data/sources/rif_relay/contracts
for file in *.json; do 
    mv -- "$file" "${file%.json}.abi.json"
done
)