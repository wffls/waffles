SHELL=/bin/bash

install:
	[[ -L /usr/local/bin/wafflescript ]] || ln -s wafflescript /usr/local/bin/

uninstall:
	[[ -L /usr/local/bin/wafflescript ]] && rm /usr/local/bin/wafflescript

.PHONY: docs
docs:
	cd docs/tools && bash mkdocs.sh
