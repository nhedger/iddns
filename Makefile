PREFIX?=/usr/local

install:
	cp iddns.sh $(PREFIX)/bin/iddns
	cp --backup --suffix=.orig config.example $(HOME)/.iddns
	chmod +x $(PREFIX)/bin/iddns

uninstall:
	rm $(PREFIX)/bin/iddns
