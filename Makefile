TERM ?= xterm
export TERM

%:
	@./scripts/primary_env.sh $@

help:
	@./scripts/primary_env.sh help

.PHONY: help build
