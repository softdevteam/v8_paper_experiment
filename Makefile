export USE_REMOTEEXEC ?= false
export ITERS ?= 10
export PATH := $(PWD)/depot_tools:$(PATH)

PWD != pwd
CHR_SRC = $(PWD)/chromium/src
CB = $(CHR_SRC)/third_party/crossbench/cb.py
GN_REL_ARGS = is_debug=false dcheck_always_on=false is_component_build=true enable_nacl=false

ifeq ($(USE_REMOTEEXEC),true)
	GN_REL_ARGS := $(GN_REL_ARGS) use_remoteexec=true
endif

HANDLES_ARGS = $(GN_REL_ARGS) v8_enable_conservative_stack_scanning=false 
HANDLES_NC_ARGS = $(GN_REL_ARGS) v8_enable_conservative_stack_scanning=false v8_enable_pointer_compression=false 
CSS_ARGS = $(GN_REL_ARGS) v8_enable_conservative_stack_scanning=true 
CSS_NC_ARGS = $(GN_REL_ARGS) v8_enable_conservative_stack_scanning=true v8_enable_pointer_compression=false 

all: build 

.PHONY: build handles handles-no-compression css css-no-compression
.PHONY: bench speedometer jetstream motionmark
.PHONY: clean clean-builds clean-results

speedometer:
	$(CB) speedometer2.1 \
		--repeat=$(ITERS) \
		--browser=$(CHR_SRC)/out/handles \
		--browser=$(CHR_SRC)/out/css \
		--browser=$(CHR_SRC)/out/handles-no-compression \
		--browser=$(CHR_SRC)/out/css-no-compression

jetstream:
	$(CB) js3 \
		--repeat=$(ITERS) \
		--browser=$(CHR_SRC)/out/handles \
		--browser=$(CHR_SRC)/out/css \
		--browser=$(CHR_SRC)/out/handles-no-compression \
		--browser=$(CHR_SRC)/out/css-no-compression

motionmark:
	$(CB) mm1.3 \
		--repeat=$(ITERS) \
		--browser=$(CHR_SRC)/out/handles \
		--browser=$(CHR_SRC)/out/css \
		--browser=$(CHR_SRC)/out/handles-no-compression \
		--browser=$(CHR_SRC)/out/css-no-compression


build: handles handles-no-compression css css-no-compression

depot-tools:
	git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

$(CHR_SRC): 
	mkdir chromium
	cd chromium && fetch --no-history chromium
	cd $@ && gclient runhooks

handles: $(CHR_SRC)
	cd $(CHR_SRC) && gn gen --args="$(HANDLES_ARGS)" out/$@
	autoninja -C out/$@ chrome chromedriver

css: $(CHR_SRC)
	cd $(CHR_SRC) && gn gen --args="$(CSS_ARGS)" out/$@
	autoninja -C out/$@ chrome chromedriver

handles-no-compression: $(CHR_SRC)
	cd $(CHR_SRC) && gn gen --args="$(HANDLES_NC_ARGS)" out/$@
	autoninja -C out/$@ chrome chromedriver

css-no-compression: $(CHR_SRC)
	cd $(CHR_SRC) && gn gen --args="$(CSS_NC_ARGS)" out/$@
	autoninja -C out/$@ chrome chromedriver

clean-results:
	rm -rf $(CHR_SRC)/third_party/crossbench/results

clean-builds:
	rm -rf $(CHR_SRC)/out/handles
	rm -rf $(CHR_SRC)/out/handles-no-compression
	rm -rf $(CHR_SRC)/out/css
	rm -rf $(CHR_SRC)/out/css-no-compression

clean: clean-confirm clean-builds
	rm -rf $(PWD)/chromium
	rm -rf $(PWD)/depot_tools
	@echo "Clean"

clean-confirm:
	@echo $@
	@( read -p "Are you sure? [y/N]: " sure && case "$$sure" in [yY]) true;; *) false;; esac )
