# Need $(EMSCRIPTEN), for example run with        emmake make

EMSCRIPTEN?=/usr/bin

EMCC=$(EMSCRIPTEN)/emcc

CFLAGS=-DSQLITE_OMIT_LOAD_EXTENSION -DSQLITE_DISABLE_LFS -DLONGDOUBLE_TYPE=double -DSQLITE_INT64_TYPE="long long int" -DSQLITE_THREADSAFE=0 -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS -DSQLITE_OMIT_WAL=1 -DSQLITE_OMIT_FLOATING_POINT=1 -DSQLITE_OMIT_VIRTUALTABLE=1 -DSQLITE_OMIT_PRAGMA=1 -DSQLITE_OMIT_FOREIGN_KEY=1 -DSQLITE_OMIT_AUTOVACUUM=1 -DSQLITE_OMIT_SUBQUERY=1 -DSQLITE_OMIT_COMPOUND_SELECT=1 -DSQLITE_OMIT_EXPLAIN=1 -DSQLITE_OMIT_DATETIME_FUNCS=1 -DSQLITE_OMIT_INTEGRITY_CHECK=1 -DSQLITE_OMIT_ATTACH=1 -DSQLITE_OMIT_ALTERTABLE=1 -DSQLITE_OMIT_UTF16=1 -DSQLITE_OMIT_TRIGGER=1 -DSQLITE_OMIT_SHARED_CACHE=1 -DSQLITE_OMIT_INCRBLOB=1 -DSQLITE_OMIT_ANALYZE=1 -DSQLITE_OMIT_AUTHORIZATION=1 -DSQLITE_OMIT_VACUUM=1 -DSQLITE_OMIT_PAGER_PRAGMAS=1 -DSQLITE_OMIT_OR_OPTIMIZATION=1 -DSQLITE_OMIT_VIEW=1 -DSQLITE_OMIT_BUILTIN_TEST=1 -DSQLITE_OMIT_XFER_OPT=1  -DSQLITE_OMIT_AUTOINCREMENT=1 -DSQLITE_OMIT_SCHEMA_PRAGMAS=1 -DSQLITE_OMIT_TRACE=1 -DSQLITE_OMIT_LOAD_EXTENSION=1 -DSQLITE_OMIT_AUTOMATIC_INDEX=1 -DSQLITE_OMIT_LIKE_OPTIMIZATION=1 -DSQLITE_OMIT_REINDEX=1 -DSQLITE_OMIT_GET_TABLE=1 -DSQLITE_OMIT_COMPLETE=1 -DSQLITE_OMIT_TEMPDB=1 -DSQLITE_OMIT_BTREECOUNT=1 -DSQLITE_OMIT_LOCALTIME=1 -DSQLITE_OMIT_COMPILEOPTION_DIAGS=1 -DSQLITE_OMIT_FLAG_PRAGMAS=1 -DSQLITE_OMIT_QUICKBALANCE=1 -DSQLITE_OMIT_CAST=1 -DSQLITE_OMIT_CHECK=1 -DSQLITE_OMIT_MEMORYDB=1 -DSQLITE_OMIT_BLOB_LITERAL=1 -DSQLITE_OMIT_SCHEMA_VERSION_PRAGMAS=1 -DSQLITE_DISABLE_DIRSYNC=1 -DSQLITE_OMIT_DECLTYPE=1 -DSQLITE_OMIT_DEPRECATED=1 -DSQLITE_OMIT_BETWEEN_OPTIMIZATION=1 -DSQLITE_OMIT_PROGRESS_CALLBACK=1 -DSQLITE_OMIT_TRUNCATE_OPTIMIZATION=1 -DSQLITE_OMIT_TCL_VARIABLE=1

all: optimized debug optimized-wasm debug-wasm js/sql.js js/sql-wasm.js

js/sql.js: js/sql-optimized.js
	cp $^ $@

js/sql-wasm.js: js/sql-optimized-wasm.js
	cp $^ $@

# RESERVED_FUNCTION_POINTERS setting is used for registering custom functions
debug-wasm: EMFLAGS= -O1 -g -s INLINING_LIMIT=10 -s RESERVED_FUNCTION_POINTERS=64 -s NO_EXIT_RUNTIME=1 -s WASM=1 -s "BINARYEN_METHOD='native-wasm'"
debug-wasm: js/sql-debug-wasm.js

optimized-wasm: EMFLAGS= --memory-init-file 0 --closure 1 -Oz -s INLINING_LIMIT=50 -s NO_EXIT_RUNTIME=1 -s RESERVED_FUNCTION_POINTERS=64 -s WASM=1 -s "BINARYEN_METHOD='native-wasm'"
optimized-wasm: js/sql-optimized-wasm.js

debug: EMFLAGS= -O1 -g -s INLINING_LIMIT=10 -s RESERVED_FUNCTION_POINTERS=64 -s NO_EXIT_RUNTIME=1
debug: js/sql-debug.js

optimized: EMFLAGS= --memory-init-file 0 --closure 1 -Oz -s INLINING_LIMIT=50 -s NO_EXIT_RUNTIME=1 -s RESERVED_FUNCTION_POINTERS=64
optimized: js/sql-optimized.js


js/sql%.js: js/shell-pre.js js/sql%-raw.js js/shell-post.js
	cat $^ > $@

js/sql%-raw.js: c/sqlite3.bc c/extension-functions.bc js/api.js exported_functions extra_exported_runtime_methods
	$(EMCC) $(EMFLAGS) -s EXPORTED_FUNCTIONS=@exported_functions -s EXTRA_EXPORTED_RUNTIME_METHODS=@extra_exported_runtime_methods c/extension-functions.bc c/sqlite3.bc --post-js js/api.js -o $@ ;\

c/sqlite3.bc: c/sqlite3.c
	# Generate llvm bitcode
	$(EMCC) $(CFLAGS) c/sqlite3.c -o c/sqlite3.bc

c/extension-functions.bc: c/extension-functions.c
	$(EMCC) $(CFLAGS) -s LINKABLE=1 c/extension-functions.c -o c/extension-functions.bc

module.tar.gz: test package.json AUTHORS README.md js/sql.js
	tar --create --gzip $^ > $@

clean:
	rm -rf js/sql-optimized.js js/sql-debug.js js/sql-optimized-wasm.js js/sql-debug-wasm.js js/sql.js js/sql*-raw.js js/*.wasm js/*.wast c/sqlite3.bc c/extension-functions.bc
