.PHONY: brew-update brew-install brew-check brew-clean

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

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
