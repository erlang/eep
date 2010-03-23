#
## Copyright
## 
## This document has been placed in the public domain.
##
## Author: Erlang/OTP, Raimo Niskanen
#

PERL = perl -w
EEPS_DIR = eeps
MD = ./md/Markdown.pl

all: README.html
	@$(MAKE) `$(PERL) -e '\
	    $$d = shift; \
	    opendir(D, $$d) || die; \
	    while($$_ = readdir(D)) { \
		print "$$d/$$_\n" if s/[.]md$$/.html/; \
	    }' $(EEPS_DIR)`

README.html: README.md Makefile $(MD)
	$(PERL) ./md/Markdown.pl $< > $@

eeps/eep-%.html: eeps/eep-%.md Makefile $(MD)
	$(PERL) -lpe 's{^(\[EEP\s+\d+\]:\s+\<eep-\d+)[.]md\>}{$$1.html>}' $< |\
	$(PERL) $(MD) > $@
