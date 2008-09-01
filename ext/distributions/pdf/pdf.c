#include <gsl/gsl_randist.h>
#include <ruby.h>

VALUE mPdf_chi_square(VALUE self, VALUE x, VALUE df);

/**
* PDF Distributions
* Cumulative distribution function for several distributions
*/

void Init_pdf()
{
    VALUE mPdf = rb_define_module("Pdf");
    rb_define_module_function(mPdf, "chi_square", mPdf_chi_square, 2);
}

/**
* alngam2 computes the logarithm of the gamma function.
* 
* call-seq:
*   alngam2(x)       -> Float
* 
*/
VALUE mPdf_chi_square(VALUE self, VALUE x, VALUE df) {
    return rb_float_new(gsl_ran_chisq_pdf(NUM2DBL(x),NUM2DBL(df)));
}
