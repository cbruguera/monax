# ----------------------------------------------------------
# REQUIREMENTS

# - go installed locally
# - for build_docker: docker installed locally

# ----------------------------------------------------------

SHELL := /bin/bash
REPO := $(shell pwd)
GOFILES_NOVENDOR := $(shell find ${REPO} -type f -name '*.go' -not -path "${REPO}/vendor/*")
PACKAGES_NOVENDOR := $(shell go list github.com/monax/cli/... | grep -v /vendor/)
VERSION := $(shell cat ${REPO}/version/version.go | tail -n 1 | cut -d \  -f 4 | tr -d '"')
VERSION_MIN := $(shell echo ${VERSION} | cut -d . -f 1-2)
COMMIT_SHA := $(shell echo `git rev-parse --short --verify HEAD`)

DOCKER_NAMESPACE := quay.io/eris


.PHONY: greet
greet:
	@echo "Hi! I'm the marmot that will help you with eris v${VERSION}"

### Formatting, linting and vetting

# check the code for style standards; currently enforces go formatting.
# display output first, then check for success
.PHONY: check
check:
	@echo "Checking code for formatting style compliance."
	@gofmt -l -d ${GOFILES_NOVENDOR}
	@gofmt -l ${GOFILES_NOVENDOR} | read && echo && echo "Your marmot has found a problem with the formatting style of the code." 1>&2 && exit 1 || true

# fmt runs gofmt -w on the code, modifying any files that do not match
# the style guide.
.PHONY: fmt
fmt:
	@echo "Correcting any formatting style corrections."
	@gofmt -l -w ${GOFILES_NOVENDOR}

### Dependency management for github.com/monax/cli

# erase vendor wipes the full vendor directory
.PHONY: erase_vendor
erase_vendor:
	rm -rf ${REPO}/vendor/

# install vendor uses glide to install vendored dependencies
.PHONY: install_vendor
install_vendor:
	go get github.com/Masterminds/glide
	glide install

### Building github.com/monax/cli

# build all targets in github.com/monax/cli
.PHONY: build
build:	check build_cli

# build eris
.PHONY: build_cli
build_cli:
	go build -o ${REPO}/target/cli-${COMMIT_SHA} ./cmd/monax

### Testing github.com/monax/cli

# test go unit tests
.PHONY: test_unit
test_unit:
	# run go tests sequentially for the different packages
	@go test ${PACKAGES_NOVENDOR} -p 1 -v

# test user stories for chains
.PHONY: test_chains_make
test_chains_make:
	# run user stories for chains
	@./tests/test_chains_make.sh

# test user stories for pkgs do
.PHONY: test_jobs
test_jobs:
	# run user stories for pkgs do
	@./tests/test_jobs.sh

# test monax cli
.PHONY: test
test: build test_unit test_chains_make test_jobs

### Clean up

# clean removes the target folder containing build artefacts
.PHONY: clean
clean:
	-rm -r ./target
