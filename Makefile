# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# Update dependencies
setup			:; make update-libs ; make install-deps
update-libs		:; git submodule update --init --recursive
install-deps	:; yarn install --frozen-lockfile

# Build & test & deploy
build         	:; forge build
xclean        	:; forge clean
deploy        	:; ./scripts/deploy.sh
lint          	:; yarn run lint
test            :; forge test --fork-url ${ETH_RPC_URL}
test-gasreport 	:; forge test --gas-report --fork-url ${ETH_RPC_URL}
test-fork       :; forge test --gas-report --fork-url ${ETH_RPC_URL}
watch		  	:; forge test --watch src/ --fork-url ${ETH_RPC_URL}
