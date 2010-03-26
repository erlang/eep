#
## Copyright
## 
## This document has been placed in the public domain.
##
## Author: Erlang/OTP, Raimo Niskanen
#

PERL = perl -w -CSD
EEPS_DIR = eeps
MD = md/Markdown.pl
MK = Makefile
IX = eep-index.pl
PRE = eep-pre.pl



all: README.html
	@$(MAKE) `$(PERL) -e '\
	    $$d = shift; \
	    opendir(D, $$d) || die; \
	    while($$_ = readdir(D)) { \
		print "$$d/$$_\n" if s/[.]md$$/.html/; \
	    }' $(EEPS_DIR)`

README.html: README.md $(MK) $(MD)
	$(PERL) $(MD) $< > $@

eeps/eep-0000.html: eeps/eep-*.md $(MK) $(IX) $(PRE)
	$(PERL) $(IX) eeps/eep-0000.md | $(PERL) $(PRE) |\
	$(PERL) $(MD) > $@

eeps/eep-%.html: eeps/eep-%.md $(MK) $(MD) $(PRE)
	$(PERL) $(PRE) $< | $(PERL) $(MD) > $@
