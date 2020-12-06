use wasm_bindgen::prelude::*;
use js_sys::Promise;

#[wasm_bindgen(module = "/js/util.js")]
extern "C" {
    pub(super) fn sleep(ms: u32) -> Promise;
}

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = console)]
    pub(super) fn log(s: &str);
}
