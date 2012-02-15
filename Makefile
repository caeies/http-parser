CC?=gcc
AR?=ar
GIT?=git

LIBEXT?=so
LIBPRE?=lib

CPPFLAGS += -I.
CPPFLAGS_DEBUG = $(CPPFLAGS) -DHTTP_PARSER_STRICT=1 -DHTTP_PARSER_DEBUG=1
CPPFLAGS_DEBUG += $(CPPFLAGS_DEBUG_EXTRA)
CPPFLAGS_FAST = $(CPPFLAGS) -DHTTP_PARSER_STRICT=0 -DHTTP_PARSER_DEBUG=0
CPPFLAGS_FAST += $(CPPFLAGS_FAST_EXTRA)

CFLAGS += -Wall -Wextra -Werror
CFLAGS_DEBUG = $(CFLAGS) -O0 -g $(CFLAGS_DEBUG_EXTRA)
CFLAGS_FAST = $(CFLAGS) -O3 $(CFLAGS_FAST_EXTRA)
CFLAGS_LIB = -fPIC

GIT_VERSION:=$(shell $(GIT) log -1 --format=%H || echo Unknown)$(shell $(GIT) status --porcelain |grep "^[ MARCDU][ MDAU] " > /dev/null && echo "-Modified")

test: ltest_g test_g test_fast
	./ltest_g
	./test_g
	./test_fast

ltest: test.o $(LIBPRE)http_parser.$(LIBEXT)
	$(CC) $(OPT_FAST) -o $@ -Wl,-rpath=. -L. -lhttp_parser $<

ltest_g: test_g.o $(LIBPRE)http_parser_g.$(LIBEXT)
	$(CC) $(OPT_FAST) -o $@ -Wl,-rpath=. -L. -lhttp_parser_g $<

test_g: http_parser_g.a test_g.o
	$(CC) $(CFLAGS_DEBUG) $(LDFLAGS) test_g.o http_parser_g.a -o $@

test_g.o: test.c http_parser.h Makefile
	$(CC) $(CPPFLAGS_DEBUG) $(CFLAGS_DEBUG) -c test.c -o $@

http_parser_g.o: http_parser.c http_parser.h Makefile
	$(CC) $(CPPFLAGS_DEBUG) $(CFLAGS_DEBUG) $(CFLAGS_LIB) -c $< -o $@

test_fast: http_parser.a test.o http_parser.h
	$(CC) $(CFLAGS_FAST) $(LDFLAGS) test.o http_parser.a -o $@

test.o: test.c http_parser.h Makefile
	$(CC) $(CPPFLAGS_FAST) $(CFLAGS_FAST) -c test.c -o $@

http_parser.o: http_parser.c http_parser.h Makefile
	$(CC) $(CPPFLAGS_FAST) $(CFLAGS_FAST) $(CFLAGS_LIB) -c $<

test-run-timed: test_fast
	while(true) do time ./test_fast > /dev/null; done

http_parser.a: http_parser.o version.o
	$(AR) rcs $@ $^

http_parser_g.a: http_parser_g.o version_g.o
	$(AR) rcs $@ $^

$(LIBPRE)http_parser.$(LIBEXT): http_parser.o version.o
	$(CC) -shared -Wl,-rpath=. -o $@ $^

$(LIBPRE)http_parser_g.$(LIBEXT): http_parser_g.o version_g.o
	$(CC) -shared -Wl,-rpath=. -o $@ $^

version-$(GIT_VERSION).c : Makefile http_parser.c http_parser.h
	echo "const char * http_git_version() { return \"$(GIT_VERSION)\"; }" > $@

version.o: version-$(GIT_VERSION).c
	$(CC) $(CFLAGS_FAST)  -c $< -o $@

version_g.o: version-$(GIT_VERSION).c
	$(CC) $(CFLAGS_DEBUG) -c $< -o $@

test-valgrind: test_g
	valgrind ./test_g

libhttp_parser.o: http_parser.c http_parser.h Makefile
	$(CC) $(CPPFLAGS_FAST) $(CFLAGS_LIB) -c http_parser.c -o libhttp_parser.o

tags: http_parser.c http_parser.h test.c
	ctags $^

clean:
	rm -f *.o *.a *.so test test_fast test_g http_parser.tar tags version-*.c

.PHONY: clean package test-run test-run-timed test-valgrind
