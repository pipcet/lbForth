CC = gcc
M32 = -m32
CFLAGS = $(M32) -O2 -fomit-frame-pointer -fno-unit-at-a-time
CPPFLAGS = -I$(TDIR)
LDFLAGS = $(M32)

META-OUTPUT = kernel.c
RUN = $(TDIR)/run.sh

JS = js

METACOMPILE ?= echo 'include $(META)  bye' | $(RUN) ./forth | tail -n+3 > $@ ; \
	$(GREP) Meta-OK $@

html: forth.js
	cp forth.js targets/asmjs/html

$(TFORTH): forth.js
	(echo "#!/bin/sh"; echo "$(JS) ./forth.js") > $@
	chmod u+x $@
	true

forth.js: forth2asmjs.js
	$(JS) $< > $@

forth2asmjs.js: $(TDIR)/common.js $(TDIR)/js2asmjs.js kernel.js
	cat $^ > $@

kernel.js: b-forth $(DEPS) $(PARAMS) $(META)
	$(METACOMPILE)

params.fth: params $(TSTAMP)
	$(RUN) ./$< -forth > $@

params: $(TDIR)/params.c $(TDIR)/forth.h $(TDIR)/forth.mk
	$(CC) $(CFLAGS) $(CPPFLAGS) $< -o $@

jump.fth: $(TDIR)/jump.fth $(TSTAMP)
	cp $< $@

threading.fth: targets/ctc.fth $(TSTAMP)
	cp $< $@

target.fth: $(TDIR)/target.fth $(TSTAMP)
	cp $< $@
	echo ": sysdir   s\" src/\" ;" >> $@

t-clean:
	rm -f *.o kernel.c params* $(PARAMS)
