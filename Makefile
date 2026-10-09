.DEFAULT_GOAL := help

.PHONY: install stow stow-check unstow test brew-install brew-check yabai-sa yabai-spaces help

install:
	@bash install/bootstrap.sh

stow:
	@bash install/link.sh --apply

stow-check:
	@bash install/link.sh --dry-run

unstow:
	@bash install/link.sh --unlink

test:
	python3 -m unittest discover -s tests

brew-install:
	brew bundle install --file=install/Brewfile

brew-check:
	brew bundle check --file=install/Brewfile

yabai-sa:
	@bash modules/yabai/bin/load-sa.sh

yabai-spaces:
	@bash modules/yabai/bin/setup-spaces.sh

help:
	@printf '%s\n' \
	  'make install       Set up macOS (Homebrew required) or Omarchy' \
	  'make stow-check    Preview links and backups' \
	  'make stow          Link configs, backing up conflicts' \
	  'make unstow        Remove managed links; backups stay available' \
	  'make test          Test linking and backups in temporary homes' \
	  'make brew-install  Install macOS packages' \
	  'make brew-check    Check macOS packages' \
	  'make yabai-sa      Authorize the macOS scripting addition' \
	  'make yabai-spaces  Restore macOS workspace labels'
