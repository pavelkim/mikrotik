VERSION := $(shell cat .version )
PWD := $(shell pwd)
SRC_DIR = $(PWD)/src
BUILD_DIR = $(PWD)/build

.PHONY: all version build clean

build: $(BUILD_DIR) health_exporter interface_traffic_usage
	@echo "Last steps"

health_exporter:
	@echo target is $@
	sed -e "s/:local version.*/:local version $(VERSION)/" "$(SRC_DIR)/$@/mikrotik_$@.rsc" > "$(BUILD_DIR)/mikrotik_$@.rsc"
	[ -f "$(SRC_DIR)/$@/mikrotik_$@.rsc-e" ] && rm "$(SRC_DIR)/$@/mikrotik_$@.rsc-e" || :

interface_traffic_usage:
	@echo target is $@
	sed -e "s/:local version.*/:local version $(VERSION)/" "$(SRC_DIR)/$@/mikrotik_$@.rsc" > "$(BUILD_DIR)/mikrotik_$@.rsc"
	[ -f "$(SRC_DIR)/$@/mikrotik_$@.rsc-e" ] && rm "$(SRC_DIR)/$@/mikrotik_$@.rsc-e" || :

version:
	@echo "Version: $(VERSION)"

clean:
	[ -d "$(BUILD_DIR)" ] && rm -rv "$(BUILD_DIR)" || :

$(BUILD_DIR):
	mkdir -p "$(BUILD_DIR)"
