# PostgreSQL extension makefile for pg_json_diff

MODULE_big = pg_json_diff
OBJS = src/pg_json_diff.o src/json_diff_impl.o

EXTENSION = pg_json_diff
DATA = pg_json_diff--1.0.sql

# C++ compilation flags
PG_CPPFLAGS = -I$(shell pwd)/include -std=c++17 -fPIC
PG_CXXFLAGS = -std=c++17 -fPIC -Wall -Wextra

# Use C++ compiler for linking
SHLIB_LINK = -lstdc++

# PostgreSQL PGXS Makefile
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

# Override compiler to use C++ for .cpp files
%.o: %.cpp
	$(CXX) $(CPPFLAGS) $(PG_CPPFLAGS) $(CXXFLAGS) $(PG_CXXFLAGS) -c -o $@ $<

.PHONY: test
test:
	psql -f test/test_pg_json_diff.sql

