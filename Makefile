PREFIX ?= /usr/local/bin

install:
	install -m 755 ralph-loop.sh $(PREFIX)/ralph-loop

uninstall:
	rm -f $(PREFIX)/ralph-loop

.PHONY: install uninstall
