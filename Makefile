MSCS_USER  ?= minecraft
MSCS_GROUP ?= minecraft
INSTALL_ROOT ?=/
MSCS_HOME  ?= $(INSTALL_ROOT)opt/mscs
INSTALL_PREFIX ?= $(INSTALL_ROOT)usr/local
INSTALL_CONF_PREFIX ?= $(INSTALL_ROOT)etc
MSCTL := $(INSTALL_PREFIX)/bin/msctl
MSCS := $(INSTALL_PREFIX)/bin/mscs
MSCS_INIT_D := $(INSTALL_CONF_PREFIX)/init.d/mscs
MSCS_SERVICE := $(INSTALL_CONF_PREFIX)/systemd/system/mscs.service
MSCS_COMPLETION := $(INSTALL_CONF_PREFIX)/bash_completion.d/mscs

UPDATE_D := $(wildcard update.d/*)

.PHONY: install update clean

install: $(MSCS_HOME) $(INSTALL_PREFIX)/bin $(INSTALL_CONF_PREFIX)/init.d/ $(INSTALL_CONF_PREFIX)/bash_completion.d/ update
	-useradd --system --user-group --create-home --home $(MSCS_HOME) $(MSCS_USER)
	chown -R $(MSCS_USER):$(MSCS_GROUP) $(MSCS_HOME)
	if which systemctl; then systemctl -f enable mscs.service; \
	else if which update-rc.d; then ln -s $(MSCS) $(MSCS_INIT_D); update-rc.d mscs defaults; fi ;fi

update:
	cp msctl $(MSCTL)
	sed 's/^[[:blank:]]*USER_NAME=.*$$/USER_NAME="$(MSCS_USER)"/;s#^[[:blank:]]*LOCATION=.*$$#LOCATION="$(MSCS_HOME)"#'  mscs > $(MSCS)
	chmod 755 $(MSCS)
	cp mscs.completion $(MSCS_COMPLETION)
	if which systemctl; then \
		cp mscs.service $(MSCS_SERVICE); \
	fi
	@for script in $(UPDATE_D); do \
		sh $$script; \
	done; true;

clean:
	if which systemctl; then \
		systemctl -f disable mscs.service; \
		rm -f $(MSCS_SERVICE); \
	else \
		update-rc.d mscs remove; \
		rm -f $(MSCS_INIT_D); \
	fi
	rm -f $(MSCTL) $(MSCS) $(MSCS_COMPLETION)

$(MSCS_HOME) $(INSTALL_CONF_PREFIX)/init.d/ $(INSTALL_CONF_PREFIX)/bash_completion.d/ $(INSTALL_PREFIX)/bin:
	mkdir -p -m 755 $@
