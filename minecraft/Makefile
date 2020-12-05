.PHONY: help install

PREFIX := /usr/local

help:
	@echo 'Run `make install` to install'

install:
	install -D -t $(PREFIX)/bin minecraft-server
	install -D -t $(PREFIX)/lib/systemd/system minecraft.service

