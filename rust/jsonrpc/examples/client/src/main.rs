#[tokio::main]
async fn main() -> jsonrpc::Result<()> {
    let mut client = jsonrpc::client::connect("127.0.0.1:5000").await?;
    let response = client.call("hello", None).await?;

    println!("Response: {:?}", response);

    Ok(())
}
