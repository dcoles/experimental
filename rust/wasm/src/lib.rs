mod util;

use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub async fn greet_async(name: JsValue) {
    log!("Hello...");
    util::sleep(5_000).await;
    log!("{}!", name.as_string().unwrap_or(String::from("world")));
}
