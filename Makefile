export USE_REMOTEEXEC ?= false
export USE_XVFB ?= false
export ITERS ?= 10
export PATH := $(PWD)/depot_tools:$(PATH)

PWD != pwd
CHR_SRC = $(PWD)/chromium/src
CB = $(CHR_SRC)/third_party/crossbench/cb.py

CFGS = $(wildcard $(PWD)/configs/*.gn)
NINJA_FILES := $(patsubst $(PWD)/configs/%.gn,$(CHR_SRC)/out/%/args.gn,$(CFGS))
CHROME_TARGETS := $(patsubst $(CHR_SRC)/out/%/args.gn,$(CHR_SRC)/out/%/chrome,$(NINJA_FILES))
BENCHMARKS = speedometer2.1 jetstream3.0 motionmark1.3

.PHONY: build bench clean

all: build bench
bench: $(BENCHMARKS)

ifeq ($(USE_XVFB),true)
XVFB_PID = $(PWD)/xvfb.pid
$(BENCHMARKS):
	Xvfb :99 -ac -screen 0 1024x268x24 & echo $$! > $(XVFB_PID)
	- DISPLAY=:99 $(CB) $@ --repeat=$(ITERS) \
		$(foreach browser, $(CHROME_TARGETS), \
		--browser=$(browser))
	kill `cat $(XVFB_PID)` && rm $(XVFB_PID)
else
$(BENCHMARKS):
	$(CB) $@ --repeat=$(ITERS) \
		$(foreach browser, $(CHROME_TARGETS), \
		--browser=$(browser))
endif

depot-tools:
	git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

$(CHR_SRC): 
	mkdir chromium
	cd chromium && fetch --no-history chromium
	cd $@ && gclient runhooks

build: $(NINJA_FILES) $(CHROME_TARGETS)

ifeq ($(USE_REMOTEEXEC),true)
$(CHR_SRC)/out/%/args.gn: $(PWD)/configs/%.gn
	cd $(CHR_SRC) && gn gen --args="$(shell cat $<) use_remoteexec=true" $(dir $@)
else
$(CHR_SRC)/out/%/args.gn: $(PWD)/configs/%.gn
	cd $(CHR_SRC) && gn gen --args="$(shell cat $<)" $(dir $@)
endif

$(CHR_SRC)/out/%/chrome: $(CHR_SRC)/out/%/args.gn
	autoninja -C $(dir $@) chrome chromedriver

clean-results:
	rm -rf $(CHR_SRC)/third_party/crossbench/results

clean-builds:
	rm -rf $(CHR_SRC)/out

clean: clean-confirm clean-builds
	rm -rf $(PWD)/chromium
	rm -rf $(PWD)/depot_tools

clean-confirm:
	@echo $@
	@( read -p "Are you sure? [y/N]: " sure && case "$$sure" in [yY]) true;; *) false;; esac )
