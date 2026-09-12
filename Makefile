# Every directory under modules/ is a stow package. Adding a tool means adding
# a directory -- nothing in here needs to change.
MODULES     := $(notdir $(wildcard modules/*))
BREWFILE    := install/Brewfile

# A module's payload sits at its root; bin/, share/ and its own docs are for
# the repo, not for $HOME. Note this matches basenames at any depth, so a
# module that genuinely needs to stow a ~/bin wants its own
# .stow-local-ignore rather than a weaker flag here.
STOW_IGNORE := --ignore='^(bin|share|install\.sh|README\.md)$$'
STOW        := stow -d modules -t "$(HOME)" $(STOW_IGNORE)

.PHONY: install stow unstow restow stow-check \
        brew-install brew-check brew-update brew-clean \
        yabai-sa yabai-spaces help

install: ## Full setup: brew bundle, stow every module, run install hooks
	@bash install/bootstrap.sh

# ----------------------------------------------------------------- stow
stow: ## Symlink every module into $HOME
	@$(STOW) -R $(MODULES)
	@echo "stowed: $(MODULES)"

unstow: ## Remove every module's symlinks from $HOME
	@$(STOW) -D $(MODULES)
	@echo "unstowed: $(MODULES)"

restow: unstow stow ## Unstow then stow (clears links left by renamed files)

stow-check: ## Dry run: show what stow would do, change nothing
	@$(STOW) -n -v -R $(MODULES)

# ----------------------------------------------------------------- brew
brew-install: ## Install packages from the Brewfile (refreshes the lock file)
	@echo "Installing packages from Brewfile..."
	brew bundle install --file=$(BREWFILE)

brew-check: ## Check installed packages against the Brewfile
	@echo "Checking packages against Brewfile..."
	brew bundle check --file=$(BREWFILE) || true

# Warning: this overwrites the Brewfile with whatever is installed right now.
# Run it on a fully set-up machine, never on a fresh one.
brew-update: ## Rewrite the Brewfile from what is installed now
	@echo "Updating Brewfile..."
	brew bundle dump --force --file=$(BREWFILE)
	@echo "Brewfile updated at $(BREWFILE)"

brew-clean: ## Remove packages not in the Brewfile
	@echo "Removing packages not in Brewfile..."
	brew bundle cleanup --force --file=$(BREWFILE)

# ------------------------------------------------------ window manager
yabai-sa: ## (Re)authorise yabai's scripting addition -- rerun after every brew upgrade
	@bash modules/yabai/bin/load-sa.sh

yabai-spaces: ## Re-provision and re-label ws1..ws9 + scratch on the main display
	@bash modules/yabai/bin/setup-spaces.sh

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'
