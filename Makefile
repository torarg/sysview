NAME                                   =       sysview
DESCR								   =	   "Static html monitoring dashboard."
PREFIX                                 ?=      /usr/local
CONFIG_PATH                            =       ${PREFIX}/share/$(NAME)
BIN_PATH                               =       ${PREFIX}/bin
MAN_SECTION                            =       1
MAN_PATH                               =       ${PREFIX}/man/man$(MAN_SECTION)
OPENBSD_PORTS_DIR              =       /usr/ports/sysutils/$(NAME)
OPENBSD_PKG_DIR                        =       /usr/ports/packages/amd64/all
OPENBSD_SIGNED_PKG_DIR =       /usr/ports/packages/amd64/all/signed
OPENBSD_PKG_KEY                        =       ~/keys/signify/1wilson-pkg.sec
OPENBSD_PKG_HOST               =       www

all:

clean:

install:
	install -m 0644 ./src/man/man1/* $(MAN_PATH)/
	install -m 0755 -d $(CONFIG_PATH)
	install -m 0755 ./src/bin/* $(BIN_PATH)/
	cp -r ./src/share/$(NAME)/* $(CONFIG_PATH)/
	chmod -R go+r $(CONFIG_PATH)/
	find $(CONFIG_PATH)/ -type d -exec chmod go+x {} \;

uninstall:
	for progname in $$(ls ./src/bin); do \
		echo "rm -fr $(BIN_PATH)/$$progname" ; \
		rm -fr $(BIN_PATH)/$$progname ; \
		echo "rm -fr $(MAN_PATH)/$$progname.1" ; \
		rm -fr $(MAN_PATH)/$$progname.1 ; \
	done
	rm -fr $(CONFIG_PATH)

clean-pkg:
	rm -fr /usr/ports/pobj/$(NAME)-*
	rm -fr rm  -r /usr/ports/plist/amd64/$(NAME)-*
	rm -fr /usr/ports/pobj/$(NAME)-*/
	rm -fr /usr/ports/packages/amd64/all/$(NAME)-*.tgz
	rm -fr $(OPENBSD_SIGNED_PKG_DIR)/$(NAME)-*.tgz
	rm -fr /usr/ports/distfiles/$(NAME)-*.tar.gz
	rm -fr $(OPENBSD_PORTS_DIR)

pkg: clean-pkg
	cp -r openbsd_package/ $(OPENBSD_PORTS_DIR)
	cd /usr/ports/sysutils/$(NAME) && \
	  make clean && \
      make makesum && \
	  make build && \
	  make fake && \
	  make update-plist && \
	  make package
	pkg_sign -C -o $(OPENBSD_SIGNED_PKG_DIR) -S $(OPENBSD_PKG_DIR) -s signify2 -s $(OPENBSD_PKG_KEY)

publish-pkg: pkg
	scp $(OPENBSD_SIGNED_PKG_DIR)/$(NAME)-*.tgz www:
	ssh $(OPENBSD_PKG_HOST) "\
		doas rm /var/www/htdocs/pub/OpenBSD/snapshots/packages/amd64/$(NAME)-*.tgz ; \
		doas cp $(NAME)-*.tgz /var/www/htdocs/pub/OpenBSD/snapshots/packages/amd64/ && \
		doas rm $(NAME)-*.tgz && \
		doas chown www /var/www/htdocs/pub/OpenBSD/snapshots/packages/amd64/$(NAME)-*.tgz \
	"

bumpversion:
	VERSION=$$(head -1 < CHANGELOG.md | awk '{ print $$2 }')  && \
		sed -i "s/^V.*=.*$$/V				=	$$VERSION/g" openbsd_package/Makefile && \
		sed -i "s/^VERSION=.*$$/VERSION=$$VERSION/g" src/bin/$(NAME) && \
		git add openbsd_package/Makefile src/bin/$(NAME) && \
		git commit -m "bump version to $$VERSION"

release-tag:
	VERSION=$$(head -1 < CHANGELOG.md | awk '{ print $$2 }') && \
		git tag $$VERSION

publish-tag:
	git push
	git push --tags

release: bumpversion release-tag publish-tag publish-pkg

doc:
	for file in src/man/man$(MAN_SECTION)/*; do \
		progname=$$(echo $$(basename $$file) | cut -f 1 -d '.') && \
		mandoc -T markdown < $$file > docs/$$progname.md; \
	done
