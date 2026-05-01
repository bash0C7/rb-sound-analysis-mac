#include <ruby.h>
#include "sound_analysis_mac.h"

static VALUE rb_sound_analysis_mac_perform(VALUE self, VALUE input) {
    const char *c_input = StringValueCStr(input);
    char *result = sound_analysis_mac_perform(c_input);
    if (result == NULL) {
        return rb_utf8_str_new_cstr("");
    }
    VALUE rb_result = rb_utf8_str_new_cstr(result);
    sound_analysis_mac_free(result);
    return rb_result;
}

void Init_sound_analysis_mac(void) {
    VALUE module = rb_define_module("SoundAnalysisMac");
    rb_define_singleton_method(module, "perform", rb_sound_analysis_mac_perform, 1);
}
