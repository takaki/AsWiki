# -*- Makefile -*-

# $Format: "VERSION = $ProjectVersion$"$
VERSION = 1.1.9

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

COPYING:
	-wget http://www.gnu.org/copyleft/gpl.txt -O $@

dist: clean COPYING
	shtool tarball -d aswiki-$(VERSION) -c gzip -o ../aswiki-$(VERSION).tar.gz .
