# -*- Makefile -*-

# $Format: "VERSION = $ProjectVersion$"$
VERSION = 0.63

all:

setup:
	-mkdir RCS
	-mkdir session
	-mkdir cache
	-mkdir attach
	-mkdir text
	 # -chmod 777 RCS session cache attach text
clean:
	find -name '*~' |xargs rm -f

dist:
	shtool tarball -d aswiki -c gzip -o ../aswiki-$(VERSION).tar.gz .