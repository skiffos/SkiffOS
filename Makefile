SHELL := /bin/bash
%:
	@cd build && make $@
help:
	@echo -e "\e[7;49;31m"
	@cat ./resources/text/logo.ascii
	@echo -e "\e[0m"
	@echo ""
	@echo "\e[0;31mConfigurations\e[0m"
	@cd ./configs/ && ../scripts/print_packages_help.sh
