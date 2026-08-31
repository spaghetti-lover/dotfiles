.PHONY: brew-update brew-install brew-check brew-clean macos-shortcuts macos-shortcuts-list macos-shortcuts-reset

BREWFILE := $(dir $(lastword $(MAKEFILE_LIST)))Brewfile

# Warning: this overwrites the Brewfile with whatever is installed right now.
# Run it on a fully set-up machine, never on a fresh one.
brew-update: ## Update Brewfile with current packages
	@echo "Updating Brewfile..."
	brew bundle dump --force --file=$(BREWFILE)
	@echo "Brewfile updated at $(BREWFILE)"

brew-install: ## Install packages from Brewfile (refreshes the lock file)
	@echo "Installing packages from Brewfile..."
	brew bundle install --file=$(BREWFILE)

brew-check: ## Check if packages match Brewfile
	@echo "Checking packages against Brewfile..."
	brew bundle check --file=$(BREWFILE) || true

brew-clean: ## Remove packages not in Brewfile
	@echo "Removing packages not in Brewfile..."
	brew bundle cleanup --force --file=$(BREWFILE)

macos-shortcuts: ## Restore macOS menu commands AeroSpace took over (ctrl-F, ctrl-T, ...)
	@bash $(dir $(lastword $(MAKEFILE_LIST)))macos-app-shortcuts.sh

macos-shortcuts-list: ## Show which menu shortcuts are currently overridden
	@bash $(dir $(lastword $(MAKEFILE_LIST)))macos-app-shortcuts.sh --list

macos-shortcuts-reset: ## Undo macos-shortcuts
	@bash $(dir $(lastword $(MAKEFILE_LIST)))macos-app-shortcuts.sh --reset

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
