SHELL := /bin/bash
%:
	@cd build && make $@
help:
	@echo -e "\e[7;49;31m"
	@cat ./resources/text/logo.ascii
	@echo -e "\e[0m"
	@echo ""
	@echo -e "\e[0;31m\033[1mConfigurations\e[0m"
	@echo -e "Set SKIFF_CONFIG to one of the following:"
	@cd ./configs/ && ../scripts/print_packages_help.sh
	@echo ""
	@echo -e "\e[0;31m\033[1mCommands\e[0m"
	@echo -e "\033[0;34mbuild\033[0m: Compiles the system."
