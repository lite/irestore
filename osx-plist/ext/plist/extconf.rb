#!/usr/bin/ruby
require 'mkmf'
$CFLAGS += ' -DNUM2LL'
$LDFLAGS += ' -framework CoreFoundation -undefined suppress -flat_namespace'
$LIBRUBYARG_SHARED=""
create_makefile("plist_ext")
