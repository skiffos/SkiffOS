SHELL := /bin/bash
%:
	@cd build && make $@
help:
	@echo -e "\e[7;49;31m"
	@cat ./resources/text/logo.ascii
	@echo -e "\e[0m"
	@echo ""
	@echo "
