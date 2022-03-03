PREFIX?=/usr/local

install:
	cp iddns.sh $(PREFIX)/bin/iddns
	if [ -f $(HOME)/.iddns ]; then \
	    cp $(HOME)/.iddns $(HOME)/.iddns.orig; \
	fi;
	cp config.example $(HOME)/.iddns
	chmod +x $(PREFIX)/bin/iddns

uninstall:
	rm $(PREFIX)/bin/iddns
