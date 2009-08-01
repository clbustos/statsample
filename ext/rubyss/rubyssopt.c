#include <ruby.h>
/**
* :stopdoc:
*/
void Init_rubyssopt();
VALUE nominal_frequencies(VALUE self);
VALUE rubyss_frequencies(VALUE self, VALUE data);
VALUE rubyss_set_valid_data(VALUE self, VALUE vector);
VALUE dataset_case_as_hash(VALUE self, VALUE index);
VALUE dataset_case_as_array(VALUE self, VALUE index);
void Init_rubyssopt()
{
    VALUE mRubySS = rb_define_module("RubySS"); 

    VALUE cNominal = rb_define_class_under(mRubySS,"Nominal",rb_cObject);
    VALUE cDataset = rb_define_class_under(mRubySS,"Dataset",rb_cObject);
    
    rb_define_const(mRubySS,"OPTIMIZED",Qtrue);
    rb_define_module_function(mRubySS,"_frequencies",rubyss_frequencies,1);
    rb_define_module_function(mRubySS,"_set_valid_data",rubyss_set_valid_data,1);
    rb_define_method(cNominal,"frequencies",nominal_frequencies,0);
    rb_define_method(cDataset,"case_as_hash",dataset_case_as_hash,1);
    rb_define_method(cDataset,"case_as_array",dataset_case_as_array,1);

}

VALUE rubyss_set_valid_data(VALUE self, VALUE vector) {
/** Emulate

@data.each do |n|
				if is_valid? n
                    @valid_data.push(n)
                    @data_with_nils.push(n)
				else
                    @data_with_nils.push(nil)
                    @missing_data.push(n)
				end
			end
            @has_missing_data=@missing_data.size>0
            */
    VALUE data=rb_iv_get(vector,"@data");
    VALUE valid_data=rb_iv_get(vector,"@valid_data");
    VALUE data_with_nils=rb_iv_get(vector,"@data_with_nils");
    VALUE missing_data=rb_iv_get(vector,"@missing_data");
    VALUE missing_values=rb_iv_get(vector,"@missing_values");
//    VALUE has_missing_data=rb_iv_get(vector,"@has_missing_data");
    long len=RARRAY_LEN(data);
    long i;
    VALUE val;
    for(i=0;i<len;i++) {
        val=rb_ary_entry(data,i);
        if(val==Qnil || rb_ary_includes(missing_values,val)) {
            rb_ary_push(missing_data,val);
            rb_ary_push(data_with_nils,Qnil);
        } else {
            rb_ary_push(valid_data,val);
            rb_ary_push(data_with_nils,val);
        }
    }
    rb_iv_set(vector,"@has_missing_data",(RARRAY_LEN(missing_data)>0) ? Qtrue : Qfalse);
    return Qnil;
}
VALUE rubyss_frequencies(VALUE self, VALUE data) {
    VALUE h;
    VALUE val;
     long len;
    long i;

	Check_Type(data,T_ARRAY);
     h=rb_hash_new();

	len=RARRAY_LEN(data);
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

