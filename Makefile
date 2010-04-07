#
## Copyright
## 
## This document has been placed in the public domain.
##
## Author: Erlang/OTP, Raimo Niskanen
#

PERL = perl -w
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
	$(PERL) $(MD) README.md > $@

eeps/eep-0000.html: eeps/eep-*.md $(MK) $(IX) $(PRE) $(MD)
	$(PERL) -CSD $(IX) eeps/eep-0000.md | $(PERL) -CSD $(PRE) | \
	$(PERL) $(MD) > $@

eeps/eep-*.html: $(MK) $(PRE) $(MD)

.SUFFIXES:
.SUFFIXES: .html .md
.md.html:
	$(PERL) -CSD $(PRE) $< | $(PERL) $(MD) > $@
