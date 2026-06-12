# Dotfiles management via GNU Stow
#
# Quick start:
#   make list                      # show all available packages
#   make stow                      # stow every (home) package into $HOME
#   make stow PKG="opencode nvim"  # stow only the named packages
#   make stow-opencode             # stow a single package (per-package target)
#   make restow PKG="opencode"     # re-sync (picks up newly added files)
#   make unstow PKG="opencode"     # remove a package's symlinks
#   make TARGET=/tmp/test stow     # override the install target (default: $HOME)
#
# Notes:
#   * --no-folding makes stow create real directories and symlink individual
#     files, so adding a new file to a package and re-stowing always links it.
#   * keyd / udev / sddm are SYSTEM configs (they target /etc, need root) and
#     are excluded from the default package list. Install them manually.

STOW       ?= stow
TARGET     ?= $(HOME)
DIR        := $(CURDIR)
STOW_FLAGS ?= --no-folding -v

# Packages that do NOT belong under $HOME (system configs under /etc, etc.)
EXCLUDE := keyd udev sddm

# Auto-detected list of stow packages: every visible top-level directory
# minus the excluded ones. (Hidden dirs like .git are not matched by */.)
ALL_PACKAGES := $(filter-out $(EXCLUDE),$(patsubst %/,%,$(wildcard */)))

# Packages to act on. Override on the command line, e.g.
#   make stow PKG="opencode nvim tmux"
PKG ?= $(ALL_PACKAGES)

.PHONY: help list stow restow unstow

help:
	@echo "Targets:"
	@echo "  make list                      List available packages"
	@echo "  make stow   [PKG=\"a b c\"]       Stow all packages, or only PKG"
	@echo "  make restow [PKG=\"a b c\"]       Re-stow (sync) packages"
	@echo "  make unstow [PKG=\"a b c\"]       Remove package symlinks"
	@echo "  make stow-<pkg>                Stow a single package (e.g. stow-opencode)"
	@echo "  make unstow-<pkg>              Unstow a single package"
	@echo "  make restow-<pkg>             Restow a single package"
	@echo ""
	@echo "Variables:"
	@echo "  TARGET=$(TARGET)  (install destination)"
	@echo "  PKG=\"$(PKG)\""

list:
	@echo "Available packages (default TARGET=$(TARGET)):"
	@for p in $(ALL_PACKAGES); do echo "  $$p"; done
	@echo ""
	@echo "Excluded (system configs, install manually): $(EXCLUDE)"

stow:
	$(STOW) -d $(DIR) -t $(TARGET) $(STOW_FLAGS) -S $(PKG)

restow:
	$(STOW) -d $(DIR) -t $(TARGET) $(STOW_FLAGS) -R $(PKG)

unstow:
	$(STOW) -d $(DIR) -t $(TARGET) $(STOW_FLAGS) -D $(PKG)

# Per-package convenience targets: make stow-opencode / unstow-nvim / restow-tmux
stow-%:
	$(STOW) -d $(DIR) -t $(TARGET) $(STOW_FLAGS) -S $*

unstow-%:
	$(STOW) -d $(DIR) -t $(TARGET) $(STOW_FLAGS) -D $*

restow-%:
	$(STOW) -d $(DIR) -t $(TARGET) $(STOW_FLAGS) -R $*
