#include "cdf.h"
#include "cdflib.h"

/**
* CDF Distributions
* Cumulative distribution function for several distributions
*/

void Init_cdf()
{
    VALUE mCdf = rb_define_module("Cdf");
    rb_define_module_function(mCdf, "alngam2", mCdf_alngam2, 1);
    rb_define_module_function(mCdf, "alnorm", mCdf_alnorm, 2);
    rb_define_module_function(mCdf, "beatin", mCdf_betain, 4);
    rb_define_module_function(mCdf, "tnc", mCdf_tnc, 3);
    rb_define_module_function(mCdf, "chi_square_p",mCdf_chi_square_p, 2);
    rb_define_module_function(mCdf, "chi_square_x",mCdf_chi_square_x,2);
    rb_define_module_function(mCdf, "chi_square_df",mCdf_chi_square_df,2);
    rb_define_module_function(mCdf, "t_p",mCdf_t_p, 2);
    rb_define_module_function(mCdf, "t_t",mCdf_t_t,2);
    rb_define_module_function(mCdf, "t_df",mCdf_t_df,2);
    rb_define_module_function(mCdf, "gamma_p",mCdf_gamma_p,3);
    rb_define_module_function(mCdf, "gamma_x",mCdf_gamma_x,3);
    rb_define_module_function(mCdf, "normal_p",mCdf_normal_p,3);
    rb_define_module_function(mCdf, "normal_x",mCdf_normal_x,3);
    rb_define_module_function(mCdf, "normal_mean",mCdf_normal_mean,3);
    rb_define_module_function(mCdf, "normal_sd",mCdf_normal_sd,3);
}

/**
* alngam2 computes the logarithm of the gamma function.
* 
* call-seq:
*   alngam2(x)       -> Float
* 
*/
VALUE mCdf_alngam2(VALUE self, VALUE xvalue) {
	int ifault;
	double ag;
	ag=alngam2 ( NUM2DBL(xvalue), &ifault);
	//printf("%f",ag);
//	1 , XVALUE is less than or equal to 0.
//    2, XVALUE is too big.
	if(ifault==1) 
	{
		rb_raise(rb_eArgError, "XVALUE is less than or equal to 0");
	} else if(ifault==2) {
		rb_raise(rb_eArgError, "XVALUE is too big");
        
	}
	return rb_float_new(ag);
}

/**
* Computes the cumulative density of the standard normal distribution
* call-seq:
*   alnorm(x,upper)       -> Float
*
* - x: is one endpoint of the semi-infinite interval 
*   over which the integration takes place.
* - upper: Input, bool UPPER, determines whether the upper or lower
*   interval is to be integrated:
*     - true  => integrate from X to + Infinity;
*     - false => integrate from - Infinity to X.
*/

VALUE mCdf_alnorm (VALUE self, VALUE x, VALUE upper ) {
    bool upper_bool=RTEST(upper);
        
    double an= alnorm( NUM2DBL(x), upper_bool);
    return rb_float_new(an);
}

VALUE mCdf_betain(VALUE self, VALUE x, VALUE p,VALUE q, VALUE beta) {
    int ifault;
    double bin=betain(NUM2DBL(x), NUM2DBL(x), NUM2DBL(x), NUM2DBL(x), &ifault);
    if(ifault) {
        rb_raise(rb_eException,"Error on betain");
    }
    return rb_float_new(bin);
}

/**
* TNC computes the tail of the noncentral T distribution.
* call-seq:
*   tnc(t,df,delta)       -> Float
*
* [t] the point whose cumulative probability is desired.
* [df] the number of degrees of freedom.
* [delta]  the noncentrality parameter. 
*
* When delta=0, tnc = t_p 
*/

VALUE mCdf_tnc(VALUE self, VALUE t, VALUE df,VALUE delta) {
    int ifault;
    double tn=tnc(NUM2DBL(t), NUM2DBL(df), NUM2DBL(delta), &ifault);
    if(ifault==1) {
        rb_raise(rb_eException,"Error on tnc");
    }
    return rb_float_new(tn);
}
/**
* Return the cumulative probability for a given value of chi for
* the cdf CHI-Square distribution 
*
* call-seq:
*   chi_square_p (x,df)
*
* [x]   Upper limit of integration of the non-central
*       chi-square distribution.
*       Input range: [0, +infinity).
*       Search range: [0,1E300]
* [df]  Degrees of freedom of the
*       chi-square distribution.
*       Input range: (0, +infinity).
*       Search range: [ 1E-300, 1E300]
*/
VALUE mCdf_chi_square_p(VALUE self, VALUE v_x,VALUE v_df) {
    int which=1;
    double p,q,x,df,bound;
    int status;
    x=NUM2DBL(v_x);
    df=NUM2DBL(v_df);
    cdfchi(&which,&p,&q,&x,&df, &status,&bound);
    return rb_float_new(p);
}

/**
* Return the chi square value for a given cumulative probability for
* the cdf CHI-Square distribution 
*
* call-seq:
*   chi_square_x (p,df)
*
* [p]   The integral from 0 to X of the chi-square
*       distribution.
*       Input range: [0, 1].
* [df]  Degrees of freedom of the
*       chi-square distribution.
*       Input range: (0, +infinity).
*       Search range: [ 1E-300, 1E300]
*/


VALUE mCdf_chi_square_x(VALUE self, VALUE v_p,VALUE v_df) {
    int which=2;
    double p,q,x,df,bound;
    int status;
    p=NUM2DBL(v_p);
    q=1-p;
    df=NUM2DBL(v_df);
    cdfchi(&which,&p,&q,&x,&df, &status,&bound);
    return rb_float_new(x);

}

/**
* Return the degrees of freedom for a given probability and 
* chi square value for the cdf CHI-Square distribution 
*
* call-seq:
*   chi_square_x (p,x)
*
* [p]   The integral from 0 to X of the chi-square
*       distribution.
*       Input range: [0, 1].
* [x]   Upper limit of integration of the non-central
*       chi-square distribution.
*       Input range: [0, +infinity).
*       Search range: [0,1E300]
*/


VALUE mCdf_chi_square_df(VALUE self, VALUE v_p,VALUE v_x) {
    int which=3;
    double p,q,x,df,bound;
    int status;
    p=NUM2DBL(v_p);
    q=1-p;
    x=NUM2DBL(v_x);
    cdfchi(&which,&p,&q,&x,&df, &status,&bound);
    return rb_float_new(df);    
}

/**
* Return the cumulative probability for a given value of t for
* the cdf t distribution 
*
* call-seq:
*   t_p (t,df)
*
* [t]   Upper limit of integration of the t-density.
*       Input range: ( -infinity, +infinity).
*       Search range: [ -1E300, 1E300 ]
* [df]  Degrees of freedom of the t-distribution.
*       Input range: (0, +infinity).
*       Search range: [1e-300, 1E10]
*/


VALUE mCdf_t_p(VALUE self, VALUE v_t,VALUE v_df) {
    int which=1;
    double p,q,t,df,bound;
    int status;
    t=NUM2DBL(v_t);
    df=NUM2DBL(v_df);
    cdft(&which,&p,&q,&t,&df, &status,&bound);
    return rb_float_new(p);
}

/**
* Return the upper limit of integration of t for a given 
* probability integration for the cdf t distribution 
*
* call-seq:
*   t_t (p,df)
*
* [p]   The integral from 0 to X of the t distribution.
*       Input range: [0, 1].
* [df]  Degrees of freedom of the t-distribution.
*       Input range: (0, +infinity).
*       Search range: [1e-300, 1E10]
*/


VALUE mCdf_t_t(VALUE self, VALUE v_p,VALUE v_df) {
    int which=2;
    double p,q,t,df,bound;
    int status;
    p=NUM2DBL(v_p);
    q=1-p;
    df=NUM2DBL(v_df);
    cdft(&which,&p,&q,&t,&df, &status,&bound);
    return rb_float_new(t);

}
VALUE mCdf_t_df(VALUE self, VALUE v_p,VALUE v_t) {
    int which=3;
    double p,q,t,df,bound;
    int status;
    p=NUM2DBL(v_p);
    q=1-p;
    t=NUM2DBL(v_t);
    cdft(&which,&p,&q,&t,&df, &status,&bound);
    return rb_float_new(df);    
}


VALUE mCdf_gamma_p(VALUE self, VALUE v_x,VALUE v_shape,VALUE v_scale) {
    int which=1;
    double p,q,x,shape,scale,bound;
    int status;
    x=NUM2DBL(v_x);
    shape=NUM2DBL(v_shape);
    scale=NUM2DBL(v_scale);
    cdfgam(&which,&p,&q,&x,&shape,&scale, &status,&bound);
    return rb_float_new(p);
}
VALUE mCdf_gamma_x(VALUE self, VALUE v_p,VALUE v_shape,VALUE v_scale) {
    int which=2;
    double p,q,x,shape,scale,bound;
    int status;
    p=NUM2DBL(v_p);
    q=1-p;
    shape=NUM2DBL(v_shape);
    scale=NUM2DBL(v_scale);
    cdfgam(&which,&p,&q,&x,&shape,&scale, &status,&bound);
    if(status==3) {
        rb_raise(rb_eException,"gamma_x:p+q!=1");
    }
        
    return rb_float_new(x);
}

VALUE mCdf_normal_p(VALUE self, VALUE v_x,VALUE v_mean,VALUE v_sd) {
    int which=1;
    double p,q,x,mean,sd,bound;
    int status;
     x=NUM2DBL(v_x);
     mean=NUM2DBL(v_mean);
     sd=NUM2DBL(v_sd);
     cdfnor(&which,&p,&q,&x, &mean,&sd,&status,&bound);
     return rb_float_new(p);
}

VALUE mCdf_normal_x(VALUE self, VALUE v_p,VALUE v_mean,VALUE v_sd) {
    int which=2;
    double p,q,x,mean,sd,bound;
    int status;
    p=NUM2DBL(v_p);
    q=1-p;
    mean=NUM2DBL(v_mean);
    sd=NUM2DBL(v_sd);
    cdfnor(&which,&p,&q,&x, &mean,&sd,&status,&bound);
    return rb_float_new(x);
}
VALUE mCdf_normal_mean(VALUE self, VALUE v_p,VALUE v_x,VALUE v_sd) {
    int which=3;
    double p,q,x,mean,sd,bound;
    int status;
    p=NUM2DBL(v_p);
    q=1-p;
    x=NUM2DBL(v_x);
    sd=NUM2DBL(v_sd);
    cdfnor(&which,&p,&q,&x, &mean,&sd,&status,&bound);
    return rb_float_new(mean);
}

VALUE mCdf_normal_sd(VALUE self, VALUE v_p,VALUE v_x,VALUE v_mean) {
    int which=4;
    double p,q,x,mean,sd,bound;
    int status;
    p=NUM2DBL(v_p);
    q=1-p;
    x=NUM2DBL(v_x);
    mean=NUM2DBL(v_mean);
    cdfnor(&which,&p,&q,&x, &mean,&sd,&status,&bound);
    return rb_float_new(sd);
}
