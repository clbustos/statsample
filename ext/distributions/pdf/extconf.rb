require "mkmf"
$CFLAGS+=" -Wall "
if find_header("gsl/gsl_randist.h")
	create_makefile("pdf")
end
