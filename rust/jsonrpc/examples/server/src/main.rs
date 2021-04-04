use std::collections::HashMap;

use serde_json::{Value, json};

#[tokio::main]
async fn main() -> jsonrpc::Result<()> {
    env_logger::init();

    let mut handlers: HashMap<_, Box<jsonrpc::Handler>> = HashMap::new();
    handlers.insert("hello".to_string(), Box::new(hello));
    handlers.insert("echo".to_string(), Box::new(echo));

    let mut server = jsonrpc::server::listen("127.0.0.1:5000", handlers).await?;
    server.run().await?;

    Ok(())
}

fn hello(_: Option<&jsonrpc::Params>) -> Result<Option<Value>, jsonrpc::message::Error> {
    Ok(Some(json!("Hello, world!")))
}

fn echo(params: Option<&jsonrpc::Params>) -> Result<Option<Value>, jsonrpc::message::Error> {
    Ok(params.map(|p| p.clone().into()))
}
