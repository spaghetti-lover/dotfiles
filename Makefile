.DEFAULT_GOAL := help

# Limit any target to some modules: make install MODULES="tmux yazi"
MODULES ?=

.PHONY: install packages packages-check packages-print stow stow-check unstow modules test yabai-sa yabai-spaces help

install:
	@bash install/bootstrap.sh $(MODULES)

packages:
	@bash install/packages.sh --install $(MODULES)

packages-check:
	@bash install/packages.sh --check $(MODULES)

packages-print:
	@bash install/packages.sh --print $(MODULES)

stow:
	@bash install/link.sh --apply $(MODULES)

stow-check:
	@bash install/link.sh --dry-run $(MODULES)

unstow:
	@bash install/link.sh --unlink $(MODULES)

modules:
	@for conf in modules/*/module.conf; do \
	  module="$${conf#modules/}"; module="$${module%/module.conf}"; \
	  platforms="$$(awk '$$1 == "platforms" { $$1 = ""; print }' "$$conf")"; \
	  printf '%-10s %s\n' "$$module" "$${platforms:- macos omarchy}"; \
	done

test:
	python3 -m unittest discover -s tests

yabai-sa:
	@bash modules/yabai/bin/load-sa.sh

yabai-spaces:
	@bash modules/yabai/bin/setup-spaces.sh

help:
	@printf '%s\n' \
	  'make install         Install packages, link configs and run hooks' \
	  'make packages        Install packages only' \
	  'make packages-check  Check packages are installed' \
	  'make packages-print  Show the Brewfile generated for this OS' \
	  'make stow-check      Preview links and backups' \
	  'make stow            Link configs, backing up conflicts' \
	  'make unstow          Remove managed links; backups stay available' \
	  'make modules         List modules and the platforms they run on' \
	  'make test            Test linking and package lists in temporary homes' \
	  'make yabai-sa        Authorize the macOS scripting addition' \
	  'make yabai-spaces    Restore macOS workspace labels' \
	  '' \
	  'Add MODULES="tmux yazi" to any install, packages or stow target to limit it.'
