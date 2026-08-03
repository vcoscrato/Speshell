.PHONY: lint test local-package-install

lint:
	qmllint -W 0 shell.qml core/*.qml components/*.qml services/*.qml theme/*.qml widgets/*.qml

test:
	QT_QPA_PLATFORM=offscreen qmltestrunner -input tests

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
