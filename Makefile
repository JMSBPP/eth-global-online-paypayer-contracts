install:
	forge install
	@echo "Installing dependencies in scaffold-balancer-v3..."
	@(cd lib/scaffold-balancer-v3 && yarn install)

.PHONY: install