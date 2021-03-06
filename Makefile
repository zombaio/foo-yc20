PREFIX=/usr/local
VERSION=
FAUST=faust

OBJS_NODEPS=src/lv2.o src/foo-yc20.o src/configuration.o src/graphics.o src/yc20-precalc.o
OBJS_JACK=src/yc20-jack.o src/main-cli.o
OBJS_GTKJACK=src/main-gui.o src/foo-yc20-ui.o
OBJS_GTK=src/foo-yc20-ui2.o src/lv2-ui.o
OBJS_CAIRO=src/yc20-base-ui.o

OBJS_DSP_STANDALONE=src/faust-dsp-standalone.o
OBJS_DSP_PLUGIN=src/faust-dsp-plugin.o

LV2_PLUGIN=src/foo-yc20.lv2/foo-yc20.so
LV2_UI=src/foo-yc20.lv2/foo-yc20-lv2ui.so

ifeq ($(CFLAGS),)
ifeq ($(shell uname), Darwin)
CFLAGS=-O3 -ffast-math -ftree-vectorize -arch ppc -arch i386 -arch x86_64
else
CFLAGS=-O3 -mtune=native -march=native -mfpmath=sse -ffast-math -ftree-vectorize
endif
endif

CFLAGS_X = $(CFLAGS) -fPIC -DVERSION=$(VERSION) -Isrc/ -Iinclude/ -DPREFIX=$(PREFIX) -Wall

$(OBJS_NODEPS): CFLAGS_use = $(CFLAGS_X) 
$(OBJS_JACK): CFLAGS_use = $(CFLAGS_X) `pkg-config --cflags jack`
$(OBJS_GTKJACK): CFLAGS_use = $(CFLAGS_X) `pkg-config --cflags gtk+-2.0` `pkg-config --cflags jack`
$(OBJS_GTK): CFLAGS_use = $(CFLAGS_X) `pkg-config --cflags gtk+-2.0`
$(OBJS_LV2): CFLAGS_use = $(CFLAGS_X)
$(OBJS_CAIRO): CFLAGS_use = $(CFLAGS_X) `pkg-config --cflags cairo`

$(OBJS_DSP_STANDALONE) $(OBJS_DSP_PLUGIN): CFLAGS_use = $(CFLAGS_X)

.cpp.o:
	$(CXX) $< $(CFLAGS_use) -c -o $@

.c.o:
	$(CXX) $< $(CFLAGS_use) -c -o $@

all: foo-yc20 foo-yc20-cli lv2

lv2: $(LV2_PLUGIN) $(LV2_UI)

## GUI version
OBJS_FOO_YC20=src/foo-yc20.o src/configuration.o src/yc20-jack.o src/main-gui.o src/foo-yc20-ui.o src/yc20-base-ui.o src/graphics.o src/yc20-precalc.o $(WIN32_RC)

foo-yc20: $(OBJS_FOO_YC20) $(OBJS_DSP_STANDALONE)
	$(CXX) $(OBJS_FOO_YC20) $(OBJS_DSP_STANDALONE) `pkg-config --libs gtk+-2.0` `pkg-config --libs jack` $(LDFLAGS_YC20) -o foo-yc20

## CLI version
OBJS_FOO_YC20_CLI=src/foo-yc20.o src/configuration.o src/main-cli.o src/yc20-jack.o src/yc20-precalc.o

foo-yc20-cli: $(OBJS_FOO_YC20_CLI) $(OBJS_DSP_STANDALONE)
	$(CXX) $(OBJS_FOO_YC20_CLI) $(OBJS_DSP_STANDALONE) $(LDFLAGS_YC20_CLI) `pkg-config --libs jack` -o foo-yc20-cli

## LV2 version
OBJS_LV2=src/lv2.o src/foo-yc20.o src/yc20-precalc.o

$(LV2_PLUGIN): $(OBJS_LV2) $(OBJS_DSP_PLUGIN)
	$(CXX) $(OBJS_LV2) $(OBJS_DSP_PLUGIN) -fPIC -shared -o $(LV2_PLUGIN) $(LDFLAGS_YC20_LV2)

## LV2 UI
OBJS_LV2_UI=src/lv2-ui.o src/foo-yc20-ui2.o src/yc20-base-ui.o src/graphics.o

$(LV2_UI): $(OBJS_LV2_UI)
	$(CXX) $(OBJS_LV2_UI) -fPIC -shared `pkg-config --libs gtk+-2.0` -o $(LV2_UI) $(LDFLAGS_YC20_LV2)

## VSTi - only compiles for windows with MinGW32. 
##        Note: Jack is used in compile flags to provide access to the ringbuffer.h. there
##              is no runtime dependency or even a library as we use the separately compiled ringbuffer.o
OBJS_VSTI_LINUX=src/vsti.o src/vstplugmain.o src/foo-yc20.o src/yc20-base-ui.o src/graphics.o
OBJS_VSTI=src/vsti.o src/vstplugmain.o src/foo-yc20.o src/yc20-base-ui.o src/graphics.o $(WIN32_RC)

$(WIN32_RC): src/win32.rc
	$(WINDRES) src/win32.rc -o src/win32.o

src/vsti.o src/vstplugmain.o: CFLAGS_use = $(CFLAGS_X) -I$(VSTSDK) -I$(VSTSDK)/public.sdk/source/vst2.x `pkg-config --cflags cairo jack`

src/vstplugmain.o: $(VSTSDK)/public.sdk/source/vst2.x/vstplugmain.cpp
	$(CXX) $(CFLAGS_use)  $(VSTSDK)/public.sdk/source/vst2.x/vstplugmain.cpp -c -o src/vstplugmain.o

vsti-linux: $(OBJS_VSTI_LINUX) $(OBJS_DSP_PLUGIN) src/vsti.def
	$(CXX) -Wall -s -shared $(CFLAGS) $(VSTFLAGS) $(OBJS_VSTI_LINUX) $(OBJS_DSP_PLUGIN) -o FooYC20.so `pkg-config --libs cairo`

vsti-windows: $(OBJS_VSTI) $(OBJS_DSP_PLUGIN) src/vsti.def
	$(CXX) -Wall -s -shared -mwindows -static $(CFLAGS) src/vsti.def $(VSTFLAGS) $(OBJS_VSTI) $(OBJS_DSP_PLUGIN) -o FooYC20.dll `pkg-config --libs cairo`

$(BIN): $(OBJ)

include/graphics-png.h: graphics/background-black.png graphics/background-blue.png graphics/background-red.png graphics/background-white.png graphics/license.png graphics/potentiometer.png graphics/black_0.png graphics/black_1.png graphics/black_2.png graphics/black_3.png graphics/green_0.png graphics/green_1.png graphics/green_2.png graphics/green_3.png graphics/white_0.png graphics/white_1.png graphics/white_2.png graphics/white_3.png
	echo "" > include/graphics-png.h
	xxd -i graphics/background-black.png >> include/graphics-png.h
	xxd -i graphics/background-blue.png >> include/graphics-png.h
	xxd -i graphics/background-red.png >> include/graphics-png.h
	xxd -i graphics/background-white.png >> include/graphics-png.h
	xxd -i graphics/license.png >> include/graphics-png.h
	xxd -i graphics/potentiometer.png >> include/graphics-png.h
	xxd -i graphics/black_0.png >> include/graphics-png.h
	xxd -i graphics/black_1.png >> include/graphics-png.h
	xxd -i graphics/black_2.png >> include/graphics-png.h
	xxd -i graphics/black_3.png >> include/graphics-png.h
	xxd -i graphics/green_0.png >> include/graphics-png.h
	xxd -i graphics/green_1.png >> include/graphics-png.h
	xxd -i graphics/green_2.png >> include/graphics-png.h
	xxd -i graphics/green_3.png >> include/graphics-png.h
	xxd -i graphics/white_0.png >> include/graphics-png.h
	xxd -i graphics/white_1.png >> include/graphics-png.h
	xxd -i graphics/white_2.png >> include/graphics-png.h
	xxd -i graphics/white_3.png >> include/graphics-png.h


src/osxringbuffer.o: ../tools/win32/jack-1.9.6/jack-1.9.6/common/ringbuffer.c
	$(CC) $(CFLAGS) \
	-I../tools/win32/jack-1.9.6/jack-1.9.6/posix/ \
	-I../tools/win32/jack-1.9.6/jack-1.9.6/common/ \
	-c ../tools/win32/jack-1.9.6/jack-1.9.6/common/ringbuffer.c \
	-o src/osxringbuffer.o

src/osxresources.o: ../tools/osx/src/osxresources.mm
	$(CC) $(CFLAGS) -o src/osxresources.o -c ../tools/osx/src/osxresources.mm

vstosx: $(OBJS_VSTI) $(OBJS_DSP_PLUGIN) src/osxringbuffer.o src/osxresources.o
	$(CXX) $(CFLAGS) \
	-I$(VSTSDK)/public.sdk -I$(VSTSDK)/vstgui.sf -I$(VSTSDK)/ \
	`pkg-config --cflags cairo` \
	-bundle -framework Carbon -framework CoreFoundation -framework AppKit \
	`pkg-config --libs cairo` \
	src/osxringbuffer.o src/osxresources.o \
	$(OBJS_VSTI) $(OBJS_DSP_PLUGIN) \
	-o vstosx

## clean

clean: cb
	rm -f $(OBJS_DSP_STANDALONE) $(OBJS_DSP_PLUGIN)

cb:
	rm -f foo-yc20 foo-yc20-cli $(LV2_PLUGIN) $(LV2_UI) FooYC20.dll
	rm -f $(OBJS_FOO_YC20) $(OBJS_FOO_YC20_CLI) $(OBJS_LV2) $(OBJS_LV2_UI) $(OBJS_VSTI)
	rm -f src/osxringbuffer.o src/osxresources.o vstosx
	


install: foo-yc20
	install -Dm 755 foo-yc20 $(DESTDIR)$(PREFIX)/bin/foo-yc20
	install -Dm 755 foo-yc20-cli $(DESTDIR)$(PREFIX)/bin/foo-yc20-cli
	install -d $(DESTDIR)$(PREFIX)/share/foo-yc20/graphics
	install -m 644 graphics/icon.png $(DESTDIR)$(PREFIX)/share/foo-yc20/graphics
	cat foo-yc20.desktop.in | sed 's!%PREFIX%!$(PREFIX)!' > foo-yc20.desktop
	install -Dm 644 foo-yc20.desktop $(DESTDIR)$(PREFIX)/share/applications/foo-yc20.desktop
	rm foo-yc20.desktop
	install -d $(DESTDIR)$(PREFIX)/lib/lv2/foo-yc20.lv2
	install -m 755 src/foo-yc20.lv2/*.so $(DESTDIR)$(PREFIX)/lib/lv2/foo-yc20.lv2
	install -m 644 src/foo-yc20.lv2/*.ttl $(DESTDIR)$(PREFIX)/lib/lv2/foo-yc20.lv2


uninstall:
	rm $(DESTDIR)$(PREFIX)/bin/foo-yc20
	rm $(DESTDIR)$(PREFIX)/bin/foo-yc20-cli
	rm $(DESTDIR)$(PREFIX)/share/applications/foo-yc20.desktop
	rm -r $(DESTDIR)$(PREFIX)/share/foo-yc20
	rm -r $(DESTDIR)$(PREFIX)/lib/lv2/foo-yc20.lv2


## Targets only for those with Faust installed

generate-source:
	$(FAUST) -a minimal.cpp faust/standalone.dsp > gen/yc20-dsp-standalone.cpp
	$(FAUST) -a minimal.cpp faust/plugin.dsp     > gen/yc20-dsp-plugin.cpp

generate-source-vec:
	$(FAUST) -vec -a minimal.cpp faust/standalone.dsp > gen/yc20-dsp-standalone.cpp
	$(FAUST) -vec -a minimal.cpp faust/plugin.dsp     > gen/yc20-dsp-plugin.cpp


basic-test:
	$(FAUST) -a jack-console.cpp faust/yc20.dsp > gen/basic.cpp
	$(CXX) $(CFLAGS) -Isrc/ gen/basic.cpp -o basic `pkg-config --cflags --libs jack`

## test compilation
# For semi-automated testing, this line is handy:
# make testit && ./testit in.wav out.wav && mhwaveedit out.wav

testit: faust/test.dsp faust/oscillator.dsp src/polyblep.cpp Makefile
	rm -rf faust/test-svg/
	$(FAUST) -svg -a sndfile.cpp faust/test.dsp > gen/test.cpp
	$(CXX) $(CFLAGS) -Isrc/ gen/test.cpp `pkg-config --cflags --libs sndfile` -o testit

$(OBJS_NODEPS) $(OBJS_JACK) $(OBJS_GTKJACK) $(OBJS_LV2) $(OBJS_CAIRO): include/*.h
src/graphics.o: include/graphics-png.h

$(OBJS_DSP_STANDALONE): gen/yc20-dsp-standalone.cpp
$(OBJS_DSP_PLUGIN): gen/yc20-dsp-plugin.cpp



