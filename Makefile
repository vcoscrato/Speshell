.PHONY: lint test local-package-install

# Prefer Qt 6 tools; on Arch, /usr/bin/qmllint may belong to Qt 5.
QT6_BIN := $(firstword $(wildcard /usr/lib/qt6/bin /usr/lib64/qt6/bin))
QMLLINT ?= $(if $(QT6_BIN),$(QT6_BIN)/qmllint,qmllint)
QMLTESTRUNNER ?= $(if $(QT6_BIN),$(QT6_BIN)/qmltestrunner,qmltestrunner)

lint:
	$(QMLLINT) -W 0 shell.qml core/*.qml components/*.qml services/*.qml theme/*.qml widgets/*.qml

test:
	QT_QPA_PLATFORM=offscreen $(QMLTESTRUNNER) -input tests

local-package-install:
	@builddir=$$(mktemp -d /tmp/speshell-local.XXXXXX); \
	printf 'Building local package in %s\n' "$$builddir"; \
	mkdir -p "$$builddir/src/speshell"; \
	cp PKGBUILD "$$builddir/"; \
	tar \
		--exclude='./src' \
		--exclude='./pkg' \
		--exclude='./speshell' \
		--exclude='./*.pkg.tar.*' \
		-cf - . | tar -C "$$builddir/src/speshell" -xf -; \
	cd "$$builddir" && makepkg -efsi
