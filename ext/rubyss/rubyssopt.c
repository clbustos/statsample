#include <ruby.h>
/**
* :stopdoc:
*/
void Init_rubyssopt();
VALUE nominal_frequencies(VALUE self);
VALUE rubyss_frequencies(VALUE self, VALUE data);
VALUE dataset_case_as_hash(VALUE self, VALUE index);
VALUE dataset_case_as_array(VALUE self, VALUE index);
void Init_rubyssopt()
{
    VALUE mRubySS = rb_define_module("RubySS"); 

    VALUE cNominal = rb_define_class_under(mRubySS,"Nominal",rb_cObject);
    VALUE cDataset = rb_define_class_under(mRubySS,"Dataset",rb_cObject);
    
    rb_define_const(mRubySS,"OPTIMIZED",Qtrue);
    
    rb_define_module_function(mRubySS,"_frequencies",rubyss_frequencies,1);
    rb_define_method(cNominal,"frequencies",nominal_frequencies,0);
    rb_define_method(cDataset,"case_as_hash",dataset_case_as_hash,1);
    rb_define_method(cDataset,"case_as_array",dataset_case_as_array,1);

}


VALUE rubyss_frequencies(VALUE self, VALUE data) {
    VALUE h=rb_hash_new();
    Check_Type(data,T_ARRAY);
    VALUE val;
    long len=RARRAY_LEN(data);
    long i;
    for(i=0;i<len;i++) {
        val=rb_ary_entry(data,i);
        if(rb_hash_aref(h,val)==Qnil) {
            rb_hash_aset(h,val,INT2FIX(1));
        } else {
            long antiguo=FIX2LONG(rb_hash_aref(h,val));
            rb_hash_aset(h,val,LONG2FIX(antiguo+1));
        }
    }
    return h;
}

VALUE nominal_frequencies(VALUE self) {
    VALUE data=rb_iv_get(self,"@data");
    return rubyss_frequencies(self,data);
}
VALUE dataset_case_as_hash(VALUE self, VALUE index) {
    VALUE vector,data,key;
    VALUE fields=rb_iv_get(self,"@fields");
    VALUE vectors=rb_iv_get(self,"@vectors");
    VALUE h=rb_hash_new();
    long len=RARRAY_LEN(fields);
    long i;
    for(i=0;i<len;i++) {
        key=rb_ary_entry(fields,i);
        vector=rb_hash_aref(vectors,key);
        data=rb_iv_get(vector,"@data");
        rb_hash_aset(h,key,rb_ary_entry(data,NUM2LONG(index)));
    }
    return h;
}
VALUE dataset_case_as_array(VALUE self, VALUE index) {
    VALUE vector,data,key;
    VALUE fields=rb_iv_get(self,"@fields");
    VALUE vectors=rb_iv_get(self,"@vectors");
    VALUE ar=rb_ary_new();
    long len=RARRAY_LEN(fields);
    long i;
    for(i=0;i<len;i++) {
        key=rb_ary_entry(fields,i);
        vector=rb_hash_aref(vectors,key);
        data=rb_iv_get(vector,"@data");
        rb_ary_push(ar,rb_ary_entry(data,NUM2LONG(index)));
    }
    return ar;
}

