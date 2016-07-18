NAME = mkumatag/keystone
VERSION = 0.1.1

ARCH=$(shell uname -i)

.PHONY: all build

ifeq ($(ARCH), x86_64)
    dockerfile = Dockerfile
else ifeq ($(ARCH), ppc64le)
    dockerfile = Dockerfile.ppc64le
endif


all: build

build:
	docker build -t $(NAME):$(VERSION) -f $(dockerfile) .
