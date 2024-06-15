PWD := $(shell pwd)
export JSONNET_PATH := $(PWD)/lib:$(PWD)/vendor

.PHONY: render-setup
render-setup: vendor/
	@jsonnet --ext-str setup=true -y main.jsonnet

.PHONY: render
render: vendor/
	@jsonnet --ext-str setup=false -y main.jsonnet

# ====== Dependencies ======

vendor/: jsonnetfile.json jsonnetfile.lock.json
	@jb install
