PREFIX?=/usr/local

install:
	cp iddns.sh $(PREFIX)/bin/iddns
	chmod +x $(PREFIX)/bin/iddns

uninstall:
	rm $(PREFIX)/bin/iddns