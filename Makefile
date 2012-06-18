
PREFIX = /usr/local
NAGIOS_DIR = /etc/nagios
TARGET = beacon.sh
PROTOS = contact_protocols
BIN_DIR = $(PREFIX)/sbin
PROTO_DIR = $(NAGIOS_DIR)/$(PROTOS)
TEMPLATES = $(PROTOS)/*.rc

.PHONY: install $(TARGET) $(TEMPLATES)

install: $(TARGET)

update:
	git pull

$(TARGET):
	install -m 0755 $(TARGET) $(BIN_DIR)/

$(TEMPLATES): $(PROTO_DIR)
	install -m 0644 $@ $(PROTO_DIR)/

$(PROTO_DIR): 
	install -d $(PROTO_DIR)

all::
	@echo "try make install"

nagios-commands:
	@echo "define command {"
	@echo "\tcommand_name service-notify-by-beacon"
	@echo "\tcommand_line /usr/local/sbin/beacon.sh --service &> /tmp/beacon.err"
	@echo "}"
	@echo "define command {"
	@echo "\tcommand_name host-notify-by-beacon"
	@echo "\tcommand_line /usr/local/sbin/beacon.sh --host &> /tmp/beacon.err"
	@echo "}"
