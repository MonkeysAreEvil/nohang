DESTDIR ?=
BINDIR ?= /usr/local/bin
CONFDIR ?= /etc
MANDIR ?= /usr/share/man/man1
LOGDIR ?= /var/log
SYSTEMDUNITDIR ?= /etc/systemd/system

all:
	@ echo "Use: make install, make uninstall"

install:
	install -d $(DESTDIR)$(BINDIR)

	install -m0755 nohang/nohang $(DESTDIR)$(BINDIR)/nohang
	install -m0755 tools/oom-sort $(DESTDIR)$(BINDIR)/oom-sort
	install -m0755 tools/psi-top $(DESTDIR)$(BINDIR)/psi-top
	install -m0755 tools/psi2log $(DESTDIR)$(BINDIR)/psi2log

	install -d $(DESTDIR)$(CONFDIR)/nohang
	-git describe --tags --long --dirty > version
	-install -m0644 version $(DESTDIR)$(CONFDIR)/nohang/version
	-rm -fv version

	install -m0644 nohang/nohang.conf $(DESTDIR)$(CONFDIR)/nohang/nohang.conf
	install -m0644 nohang/nohang.conf $(DESTDIR)$(CONFDIR)/nohang/nohang.conf.default
	install -m0644 nohang/nohang-desktop.conf $(DESTDIR)$(CONFDIR)/nohang/nohang-desktop.conf
	install -m0644 nohang/nohang-desktop.conf $(DESTDIR)$(CONFDIR)/nohang/nohang-desktop.conf.default

	install -d $(DESTDIR)$(CONFDIR)/logrotate.d
	install -m0644 nohang/nohang.logrotate $(DESTDIR)$(CONFDIR)/logrotate.d/nohang

	install -d $(DESTDIR)$(MANDIR)
	gzip -c nohang/nohang.1 > $(DESTDIR)$(MANDIR)/nohang.1.gz
	gzip -c tools/oom-sort.1 > $(DESTDIR)$(MANDIR)/oom-sort.1.gz
	gzip -c tools/psi-top.1 > $(DESTDIR)$(MANDIR)/psi-top.1.gz
	gzip -c tools/psi2log.1 > $(DESTDIR)$(MANDIR)/psi2log.1.gz

ifeq ($(shell which systemctl), /usr/sbin/systemctl)
	-install -d $(DESTDIR)$(SYSTEMDUNIT# DIR)
	-sed "s|:TARGET_BIN:|$(BINDIR)|g;s|:TARGET_CONF:|$(CONFDIR)|g" nohang/nohang.service.in > nohang.service
	-sed "s|:TARGET_BIN:|$(BINDIR)|g;s|:TARGET_CONF:|$(CONFDIR)|g" nohang/nohang-desktop.service.in > nohang-desktop.service
	-install -m0644 nohang.service $(DESTDIR)$(SYSTEMDUNITDIR)/nohang.service
	-install -m0644 nohang-desktop.service $(DESTDIR)$(SYSTEMDUNITDIR)/nohang-desktop.service
	-rm -fv nohang.service
	-rm -fv nohang-desktop.service
	-chcon -t systemd_unit_file_t $(DESTDIR)$(SYSTEMDUNITDIR)/nohang.service
	-chcon -t systemd_unit_file_t $(DESTDIR)$(SYSTEMDUNITDIR)/nohang-desktop.service
	-systemctl daemon-reload
endif

ifeq ($(shell which openrc), /sbin/openrc)
	install -d $(DESTDIR)$(CONFDIR)/init.d
	-sed "s|:TARGET_BIN:|$(BINDIR)|g;s|:TARGET_CONF:|$(CONFDIR)|g" nohang/openrc/nohang.in > nohang/openrc/nohang
	-sed "s|:TARGET_BIN:|$(BINDIR)|g;s|:TARGET_CONF:|$(CONFDIR)|g" nohang/openrc/nohang-desktop.in > nohang/openrc/nohang-desktop
	install -m0775 nohang/openrc/nohang $(DESTDIR)$(CONFDIR)/init.d/nohang
	install -m0775 nohang/openrc/nohang-desktop $(DESTDIR)$(CONFDIR)/init.d/nohang-desktop
endif

uninstall:
	# 'make uninstall' must not fail with error if systemctl/openrc is unavailable or returns error
	-systemctl stop nohang.service || true
	-systemctl stop nohang-desktop.service || true
	-systemctl disable nohang.service || true
	-systemctl disable nohang-desktop.service || true
	-systemctl daemon-reload
	-openrc-run stop nohang || true
	-openrc-run stop nohang-desktop || true
	rm -fv $(DESTDIR)$(BINDIR)/nohang
	rm -fv $(DESTDIR)$(BINDIR)/oom-sort
	rm -fv $(DESTDIR)$(BINDIR)/psi-top
	rm -fv $(DESTDIR)$(BINDIR)/psi2log
	rm -fv $(DESTDIR)$(MANDIR)/nohang.1.gz
	rm -fv $(DESTDIR)$(MANDIR)/oom-sort.1.gz
	rm -fv $(DESTDIR)$(MANDIR)/psi-top.1.gz
	rm -fv $(DESTDIR)$(MANDIR)/psi2log.1.gz
	# Similarly for removing service files
	-rm -fv $(DESTDIR)$(SYSTEMDUNITDIR)/nohang.service || true
	-rm -fv $(DESTDIR)$(SYSTEMDUNITDIR)/nohang-desktop.service || true
	-rm -fv $(DESTDIR)$(CONFDIR)/init.d/nohang || true
	-rm -fv $(DESTDIR)$(CONFDIR)/init.d/nohang-desktop || true
	rm -fvr $(DESTDIR)$(CONFDIR)/nohang/
	rm -fvr $(DESTDIR)$(CONFDIR)/logrotate.d/nohang
	rm -fvr $(DESTDIR)$(LOGDIR)/nohang/
