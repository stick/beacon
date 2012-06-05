
PREFIX = /usr/local
NAGIOS_DIR = /etc/nagios
TARGET = beacon.sh
PROTOS = contact_protocols
BIN_DIR = $(PREFIX)/sbin
PROTO_DIR = $(NAGIOS_DIR)/$(PROTOS)
TEMPLATES = $(PROTOS)/*.rc

.PHONY: install $(TARGET) $(TEMPLATES)

install: $(TARGET)

$(TARGET): $(TEMPLATES)
	install -m 0755 $(TARGET) $(BIN_DIR)/

$(TEMPLATES): $(PROTO_DIR)
	install -m 0644 $@ $(PROTO_DIR)/

$(PROTO_DIR): 
	install -d $(PROTO_DIR)

all::
	@echo "try make install"
