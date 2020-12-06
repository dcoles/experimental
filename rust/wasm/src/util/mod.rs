mod bindings;

use wasm_bindgen_futures::JsFuture;

/// Sleep for `ms` milliseconds.
pub async fn sleep(ms: u32) {
    JsFuture::from(bindings::sleep(ms)).await.unwrap();
}

/// Log a message to the console.
pub fn log(s: &str) {
    bindings::log(s);
}

#[macro_export]
macro_rules! log {
    ($($v: expr),*) => { crate::util::log(&format!($($v),*)) };
}
