# Makefile for Nim project.

NIM       ?= nim
NIMBLE    ?= nimble
TESTAMENT ?= testament
RMDIR     ?= rmdir

PACKAGE ?= $(notdir $(basename $(wildcard src/*.nim)))

ifeq ($(VERBOSE),1)
V :=
else
V := @
endif

all:

.PHONY: help
help:
	@echo "Usage $(MAKE) <target>"
	@echo
	@echo "Targets:"
	@echo "  check     - check the source"
	@echo "  gendoc    - generate package documentation"
	@echo "  install   - install the package"
	@echo "  test      - run all the tests"

.PHONY: check
check:
	@$(NIMBLE) check

.PHONY: check
test:
	@$(TESTAMENT) all

.PHONY: install
install: check
	@$(NIMBLE) install

.PHONY: force-install
force-install: check
	@$(NIMBLE) install -y

.PHONY: clean
clean:
	-@$(RM) $(basename $(wildcard tests/*/test_*.nim))
	-@$(RM) tests/megatest.nim tests/megatest

.PHONY: distclean
distclean: clean
	-@$(RM) -rf nimcache/
	-@$(RM) -rf testresults/
	-@$(RM) outputExpected.txt outputGotten.txt testresults.html

.PHONY: gendoc
gendoc:
	@$(NIMBLE) gendoc

.PHONY: watchdoc
watchdoc:
	inotifywait -e close_write --recursive --monitor --format '%e %w%f' src | \
		while read change; do \
			$(MAKE) gendoc; \
		done

.PHONY:
serve:
	python3 -m http.server

arch: clean
	@set -e; \
		project=`basename \`pwd\``; \
		timestamp=`date '+%Y-%m-%d-%H%M%S'`; \
		destfile=../$$project-$$timestamp.tar.zst; \
		tar -C .. -caf $$destfile $$project && chmod 444 $$destfile; \
		echo -n "$$destfile" | xclip -selection clipboard -i; \
		echo "Archive is $$destfile"

# vim: set ts=8 noet sts=8:
