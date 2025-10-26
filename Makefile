.PHONY: install test deploy verify clean pay

install:
	forge install

test:
	forge test -vv

deploy:
	forge script script/Deployments.s.sol --rpc-url $(ETHEREUM_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify

verify:
	forge verify-contract --chain-id 1 --num-of-optimizations 200 --watch --constructor-args $(cast abi-encode "constructor(address,address,address,address)" "0x6c3ea9036406852006290770BEdFcAbA0e23A0e8" "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2" "0x4e58BBEa423c4B9A2Fc7b8E58F5499f9927fADdE" "0x1F98431c8aD98523631AE4a59f267346ea31F984") --etherscan-api-key $(ETHERSCAN_API_KEY) 0x5c9475e14b7a4857e460702764c4d5186ffd697d src/PaymentGateway.sol:PaymentGateway

pay:
	@echo "Usage: make pay PAYER=0x... PAYMENT_TOKEN=0x... AMOUNT=1000000000000000000 PAYEE=0x... [VALUE=0]"
	@echo "Example: make pay PAYER=0x123... PAYMENT_TOKEN=0x6B175474E89094C44Da98b954EedeAC495271d0F AMOUNT=1000000000000000000 PAYEE=0x456..."
	@if [ -z "$(PAYER)" ] || [ -z "$(PAYMENT_TOKEN)" ] || [ -z "$(AMOUNT)" ] || [ -z "$(PAYEE)" ]; then \
		echo "Error: Missing required parameters"; \
		exit 1; \
	fi
	forge script script/Payments.s.sol --rpc-url $(ETHEREUM_RPC_URL) --private-key $(PRIVATE_KEY) --sig "pay(address,address,uint256,address)" $(PAYER) $(PAYMENT_TOKEN) $(AMOUNT) $(PAYEE) $(if $(VALUE),--value $(VALUE))

clean:
	forge clean