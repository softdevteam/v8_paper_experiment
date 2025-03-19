PWD != pwd
CHR_SRC = $(PWD)/chromium/src
DT_SRC = $(PWD)/depot_tools
RUNNER = $(CHR_SRC)/third_party/crossbench/cb.py

export USE_REMOTEEXEC ?= false
export ITERS ?= 10
export USE_XVFB ?= true
export PATH := $(DT_SRC):$(PATH)

ifeq ($(USE_XVFB),true)
RUNNER := xvfb-run -a $(RUNNER)
endif
PYTHON = python3
ifeq ($(USE_REMOTEEXEC),true)
REMOTEEXEC = use_remoteexec=true
endif

CFGS = $(wildcard $(PWD)/configs/*.gn)
NINJA_FILES := $(patsubst $(PWD)/configs/%.gn,$(CHR_SRC)/out/%/args.gn,$(CFGS))
CHROME_TARGETS := $(patsubst $(CHR_SRC)/out/%/args.gn,$(CHR_SRC)/out/%/chrome,$(NINJA_FILES))

BENCHMARKS = speedometer_2.1 jetstream_2.0 motionmark_1.3
RESULTS = $(PWD)/results
RAW := $(addprefix $(RESULTS)/rawdata/, $(BENCHMARKS))
RAW := $(addsuffix .json, $(RAW))
PLOTS = $(addprefix $(RESULTS)/plots/, $(addsuffix .md, $(BENCHMARKS)))

# Processing results into plots
PYTHON = python3
VENV = $(PWD)/venv
PIP = $(VENV)/bin/pip
PYTHON_EXEC = $(VENV)/bin/python

.PHONY: build bench plot clean

all: plot

plot: $(VENV)/bin/activate $(RESULTS)/plots $(PLOTS)

perf: $(CHR_SRC)
	@if [ $$(id -u) -ne 0 ]; then \
        echo "Setting CPU frequency governor requires sudo."; \
        exit 1; \
    fi
	sh $(CHR_SRC)/v8/tools/cpu.sh performance

$(RESULTS)/plots:
	mkdir -p $(RESULTS)/plots

$(VENV)/bin/activate: requirements.txt
	$(PYTHON) -m venv $(VENV)
	$(PIP) install -r $<

$(PLOTS): $(RAW)
	@echo $(PYTHON) process.py $< $@
	$(PYTHON_EXEC) process.py $< $@

bench: $(RAW)

$(RAW):
	@echo $@
	$(RUNNER) $(basename $(notdir $@)) --env-validation=skip --repeat=$(ITERS) \
		$(foreach browser, $(CHROME_TARGETS), \
		--browser=$(browser)) \
		--out-dir=$(dir $@)

build: perf $(NINJA_FILES) $(CHROME_TARGETS)

$(NINJA_FILES): $(CFGS)
	cd $(CHR_SRC) && gn gen --args="$(shell cat $<) $(REMOTEEXEC)" $(dir $@)

$(CHROME_TARGETS): $(NINJA_FILES)
	autoninja -C $(dir $@) chrome chromedriver

$(CHR_SRC): $(DT_SRC)
	mkdir chromium
	cd chromium && fetch --no-history chromium
	cd $@ && gclient runhooks

$(DT_SRC):
	git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

clean-results:
	rm -rf $(RESULTS)

clean-builds:
	rm -rf $(CHR_SRC)/out

clean: clean-confirm clean-builds
	rm -rf $(CH_SRC)
	rm -rf $(DT_SRC)

clean-confirm:
	@echo $@
	@( read -p "Are you sure? [y/N]: " sure && case "$$sure" in [yY]) true;; *) false;; esac )
