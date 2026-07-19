# Dotfiles management via GNU Stow
#
# Quick start:
#   make list                      # show all available packages
#   make agents-sync && make stow  # install default packages into $HOME
#   make stow PKG="opencode nvim"  # stow only the named packages
#   make stow-opencode             # stow a single package (per-package target)
#   make agents-sync && make restow # refresh default packages after pulling
#   make restow PKG="opencode"     # re-sync only named packages
#   make unstow PKG="opencode"     # remove a package's symlinks
#   make TARGET=/tmp/test stow     # override the install target (default: $HOME)
#
# Notes:
#   * --no-folding makes stow create real directories and symlink individual
#     files, so adding a new file to a package and re-stowing always links it.
#   * The default package list is explicit. Other packages remain available via
#     per-package targets, such as `make stow-rofi`.

STOW       ?= stow
TARGET     ?= $(HOME)
DIR        := $(CURDIR)
STOW_FLAGS ?= --no-folding -v

# Every available package directory. Hidden dirs like .git are not matched by */.
# `codex/` is intentionally ignored because its live config is machine-local.
ALL_PACKAGES := $(filter-out codex,$(patsubst %/,%,$(wildcard */)))

# Packages installed by `make stow` and `make restow`.
DEFAULT_PACKAGES := agents alacritty amp fastfetch git herdr kitty niri noctalia nvim opencode scripts tmux zprofile zsh zshenv

# Packages to act on. Defaults to the active, tested package set. Override on
# the command line for a targeted operation, e.g.
#   make stow PKG="opencode nvim tmux"
PKG ?= $(DEFAULT_PACKAGES)

.PHONY: help list stow restow unstow agents-sync verify-agent-workflow

help:
	@echo "Targets:"
	@echo "  make list                      List available packages"
	@echo "  make stow   [PKG=\"a b c\"]       Install default packages, or only PKG"
	@echo "  make restow [PKG=\"a b c\"]       Refresh default packages, or only PKG"
	@echo "  make unstow [PKG=\"a b c\"]       Remove package symlinks"
	@echo "  make agents-sync                Regenerate Claude/Codex subagents"
	@echo "  make verify-agent-workflow      Validate agent config, scripts, and safety tests"
	@echo "  make stow-<pkg>                Stow a single package (e.g. stow-opencode)"
	@echo "  make unstow-<pkg>              Unstow a single package"
	@echo "  make restow-<pkg>             Restow a single package"
	@echo ""
	@echo "Standard flows:"
	@echo "  New machine:      make agents-sync && make stow"
	@echo "  Existing machine: make agents-sync && make restow"
	@echo ""
	@echo "Variables:"
	@echo "  TARGET=$(TARGET)  (install destination)"
	@echo "  PKG=\"$(PKG)\""

list:
	@echo "Default packages (TARGET=$(TARGET)):"
	@for p in $(DEFAULT_PACKAGES); do echo "  $$p"; done
	@echo ""
	@echo "Other packages (install explicitly):"
	@for p in $(filter-out $(DEFAULT_PACKAGES),$(ALL_PACKAGES)); do echo "  $$p"; done

stow:
	$(STOW) -d $(DIR) -t $(TARGET) $(STOW_FLAGS) -S $(PKG)

restow:
	$(STOW) -d $(DIR) -t $(TARGET) $(STOW_FLAGS) -R $(PKG)

unstow:
	$(STOW) -d $(DIR) -t $(TARGET) $(STOW_FLAGS) -D $(PKG)

agents-sync:
	./scripts/.local/bin/agents-sync

verify-agent-workflow:
	./scripts/.local/bin/verify-agent-workflow

# Per-package convenience targets: make stow-opencode / unstow-nvim / restow-tmux
stow-%:
	$(STOW) -d $(DIR) -t $(TARGET) $(STOW_FLAGS) -S $*

unstow-%:
	$(STOW) -d $(DIR) -t $(TARGET) $(STOW_FLAGS) -D $*

restow-%:
	$(STOW) -d $(DIR) -t $(TARGET) $(STOW_FLAGS) -R $*
