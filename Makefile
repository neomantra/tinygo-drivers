
clean:
	@rm -rf build

FMT_PATHS = ./

fmt-check:
	@unformatted=$$(gofmt -l $(FMT_PATHS)); [ -z "$$unformatted" ] && exit 0; echo "Unformatted:"; for fn in $$unformatted; do echo "  $$fn"; done; exit 1

XTENSA ?= 1
smoke-test:
	@mkdir -p build
	@go run ./smoketest.go -xtensa=$(XTENSA) smoketest.sh


# rwildcard is a recursive version of $(wildcard) 
# https://blog.jgc.org/2011/07/gnu-make-recursive-wildcard-function.html
rwildcard=$(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))
# Recursively find all *_test.go files from cwd & reduce to unique dir names
HAS_TESTS = $(sort $(dir $(call rwildcard,,*_test.go)))
# Exclude anything we explicitly don't want to test for whatever reason
EXCLUDE_TESTS = image waveshare-epd/epd2in66b
TESTS = $(filter-out $(addsuffix /%,$(EXCLUDE_TESTS)),$(HAS_TESTS))

unit-test:
	@go test -v $(addprefix ./,$(TESTS))

# dht needs machine.CPUFrequency, which the wasm machine package does not have.
JS_BUILD_EXCLUDE_TESTS = dht
JS_BUILD_TESTS = $(filter-out $(addsuffix /%,$(JS_BUILD_EXCLUDE_TESTS)),$(TESTS))

# tinygo test -c writes one <pkg>.test file per package into the current directory.
unit-test-js-build:
	@tinygo test -c -target=wasm $(addprefix ./,$(JS_BUILD_TESTS)); status=$$?; rm -f *.test; exit $$status

# quicktest needs reflect.Type.IsVariadic, which TinyGo does not implement.
WASM_EXCLUDE_TESTS = adt7410 aht20 gps ina219 ina260 lis2mdl mcp23017 scd4x seesaw sharpmem tester $(JS_BUILD_EXCLUDE_TESTS)
WASM_TESTS = $(filter-out $(addsuffix /%,$(WASM_EXCLUDE_TESTS)),$(TESTS))

unit-test-wasm:
	@tinygo test -target=wasip1 $(addprefix ./,$(WASM_TESTS))

test: clean fmt-check unit-test unit-test-wasm unit-test-js-build smoke-test

EXCLUDE_DIRS = build cmd examples internal lora ndir netdev netlink tester

drivers-count:
	@root_count=$$(find . -mindepth 1 -maxdepth 1 -type d | grep -vE '^\./($(subst $(space),|,$(EXCLUDE_DIRS)))$$' | wc -l); \
	epd_count=$$(find ./waveshare-epd -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l); \
	total=$$((root_count + epd_count)); \
	echo "Total drivers: $$total (root: $$root_count, waveshare-epd: $$epd_count)"

drivers-list:
	@{ \
		find . -mindepth 1 -maxdepth 1 -type d | grep -vE '^\./($(subst $(space),|,$(EXCLUDE_DIRS)))$$'; \
		if [ -d ./waveshare-epd ]; then find ./waveshare-epd -mindepth 1 -maxdepth 1 -type d; fi; \
	} | sed 's|^\./||' | sort
