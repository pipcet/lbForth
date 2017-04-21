META-OUTPUT = $(TFORTH)
JS ?= /home/pip/git/asmjs/common3/bin/js

METACOMPILE ?= echo 'include $(META)  bye' | $(RUN) ./forth | tee | tail -n+3 > $@ ; \
	$(GREP) Meta-OK $@

$(TFORTH): forth.js
	(echo "#!/bin/sh"; echo "$(JS) ./forth.js") > $@
	chmod u+x $@
	true

forth.js: b-forth $(PARAMS) $(META)
	$(METACOMPILE)

jump.fth: $(TDIR)/jump.fth $(TSTAMP)
	cp $< $@

threading.fth: targets/ctc.fth $(TSTAMP)
	cp $< $@

params.fth:$ $(TDIR)/params.fth $(TSTAMP)
	cp $(TDIR)/params.fth $@

target.fth: $(TDIR)/target.fth $(TSTAMP) Makefile
	cp $(TDIR)/target.fth  $@
	echo ": sysdir   s\" $(sysdir)/\" ;" >> $@

t-clean:
	rm -f $(PARAMS)
