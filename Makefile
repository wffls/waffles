SHELL=/bin/bash

install:
	[[ -L /usr/local/bin/wafflescript ]] || ln -s $(shell pwd)/wafflescript /usr/local/bin/wafflescript

uninstall:
	[[ -L /usr/local/bin/wafflescript ]] && rm /usr/local/bin/wafflescript

.PHONY: docs
docs:
	cd docs/tools && bash mkdocs.sh
