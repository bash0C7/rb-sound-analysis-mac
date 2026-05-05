#include <ruby.h>
#include <errno.h>
#include <sys/stat.h>
#include "SoundAnalysisMac-Swift.h"

static VALUE rb_sound_analysis_mac_classify(VALUE self, VALUE path) {
    const char *c_path = StringValueCStr(path);
    struct stat st;
    if (stat(c_path, &st) != 0) {
        rb_syserr_fail(errno, c_path);
    }
    char *result = sound_analysis_mac_classify(c_path);
    if (result == NULL) {
        return rb_utf8_str_new_cstr("");
    }
    VALUE rb_result = rb_utf8_str_new_cstr(result);
    sound_analysis_mac_free(result);
    return rb_result;
}

void Init_sound_analysis_mac(void) {
    VALUE module = rb_define_module("SoundAnalysisMac");
    rb_define_singleton_method(module, "classify", rb_sound_analysis_mac_classify, 1);
}
