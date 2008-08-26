#include "rubyss_ext.h"
#include "cdflib.h"
void Init_rubyss_ext()
{
    VALUE mRubySS = rb_define_module("RubySS");
    rb_define_module_function(mRubySS, "alngam2", mRubySS_alngam2, 1);
    rb_define_module_function(mRubySS, "alnorm", mRubySS_alnorm, 2);
    rb_define_module_function(mRubySS, "beatin", mRubySS_betain, 4);
    rb_define_module_function(mRubySS, "tnc", mRubySS_tnc, 3);
rb_define_module_function(mRubySS, "chi_square_p",mRubySS_chi_square_p, 3);
rb_define_module_function(mRubySS, "chi_square_x",mRubySS_chi_square_x,3);
rb_define_module_function(mRubySS, "chi_square_df",mRubySS_chi_square_df,3);
    
    
}



VALUE mRubySS_alngam2(VALUE self, VALUE xvalue) {
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

VALUE mRubySS_alnorm (VALUE self, VALUE x, VALUE upper ) {
    bool upper_bool=RTEST(upper);
        
    double an= alnorm( NUM2DBL(x), upper_bool);
    return rb_float_new(an);
}

VALUE mRubySS_betain(VALUE self, VALUE x, VALUE p,VALUE q, VALUE beta) {
    int ifault;
    double bin=betain(NUM2DBL(x), NUM2DBL(x), NUM2DBL(x), NUM2DBL(x), &ifault);
    if(ifault) {
        rb_raise(rb_eException,"Error on betain");
    }
    return rb_float_new(bin);
}

VALUE mRubySS_tnc(VALUE self, VALUE t, VALUE df,VALUE delta) {
    int ifault;
    double tn=tnc(NUM2DBL(t), NUM2DBL(df), NUM2DBL(delta), &ifault);
    if(ifault==1) {
        rb_raise(rb_eException,"Error on tnc");
    }
    return rb_float_new(tn);
}

VALUE mRubySS_chi_square_p(VALUE self, VALUE v_x,VALUE v_df, VALUE v_bound) {
    int which=1;
    double p,q,x,df,bound;
    int status;
    x=NUM2DBL(v_x);
    df=NUM2DBL(v_df);
    bound=NUM2INT(v_bound);
    cdfchi(&which,&p,&q,&x,&df, &status,&bound);
    return rb_float_new(p);
}
VALUE mRubySS_chi_square_x(VALUE self, VALUE v_p,VALUE v_df, VALUE v_bound) {
    int which=2;
    double p,q,x,df,bound;
    int status;
    p=NUM2DBL(v_p);
    q=1-p;
    df=NUM2DBL(v_df);
    bound=NUM2INT(v_bound);
    cdfchi(&which,&p,&q,&x,&df, &status,&bound);
    return rb_float_new(x);

}
VALUE mRubySS_chi_square_df(VALUE self, VALUE v_p,VALUE v_x, VALUE v_bound) {
    int which=3;
    double p,q,x,df,bound;
    int status;
    p=NUM2DBL(v_p);
    q=1-p;
    x=NUM2DBL(v_x);
    bound=NUM2INT(v_bound);
    cdfchi(&which,&p,&q,&x,&df, &status,&bound);
    return rb_float_new(df);    
}


