forge create --rpc-url ${DEPLOY_RPC_URL} \
    --constructor-args ${TOKEN_IN} ${TOKEN_OUT} 750 31536000 1706831999 ${DEPLOYER_ADDRESS} \
    --private-key ${DEPLOYER_KEY} src/TokenConversion.sol:TokenConversion \
    --etherscan-api-key ${ETHERSCAN_API_KEY} \
    --verify
