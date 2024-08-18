/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "napi/native_api.h"
#include "image_edit.h"

napi_property_descriptor DESCRIPTOR(const char *name, napi_callback cb)
{
    napi_property_descriptor desc = {name, nullptr, cb, nullptr, nullptr, nullptr, napi_default, nullptr};
    return desc;
}

EXTERN_C_START
void RegisterCustomBrightness() { ImageEdit::RegisterCustomBrightness(); }

static napi_value Init(napi_env env, napi_value exports)
{
    RegisterCustomBrightness();

    napi_property_descriptor desc[] = {
        DESCRIPTOR("apply", ImageEdit::Apply),
        DESCRIPTOR("lookupFilterInfo", ImageEdit::LookupFilterInfo),
        DESCRIPTOR("lookupFilters", ImageEdit::LookupFilters),
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = ((void *)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void) { napi_module_register(&demoModule); }