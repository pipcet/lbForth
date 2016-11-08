CC = gcc
M32 = -m32
CFLAGS = $(M32) -O0 -ggdb3 -fno-unit-at-a-time
CPPFLAGS = -I$(TDIR)
LDFLAGS = $(M32)

META-OUTPUT = kernel.c
RUN = $(TDIR)/run.sh

METACOMPILE ?= echo 'include $(META)  bye' | $(RUN) ./forth | tail -n+3 > $@ ; \
	$(GREP) Meta-OK $@

$(TFORTH): kernel.o
	$(CC) $(LDFLAGS) $^ -o $@

kernel.o: kernel.c $(TDIR)/forth.h

kernel.c: b-forth $(DEPS) $(PARAMS) $(META)
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
