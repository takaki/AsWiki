# -*- Makefile -*-

# $Format: "VERSION = $ProjectVersion$"$
VERSION = 0.91

all:

setup:
	-mkdir -p RCS
	-mkdir -p session
	-mkdir -p cache
	-mkdir -p attach
	-mkdir -p text
	 # -chmod 777 RCS session cache attach text
clean:
	find -name '*~' |xargs rm -f

dist:
	shtool tarball -d aswiki -c gzip -o ../aswiki-$(VERSION).tar.gz .