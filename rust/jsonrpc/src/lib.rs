pub mod channel;
pub mod client;
pub mod message;
pub mod server;

pub use message::Params;
pub use server::Handler;

pub type Result<T> = std::result::Result<T, Error>;

#[derive(thiserror::Error, Debug)]
pub enum Error {
    #[error("rpc error")]
    RPC(message::Error),
    #[error("protocol error")]
    Protocol(String),
    #[error("serialization error")]
    Serialization(#[from] serde_json::Error),
    #[error("connection error")]
    Connection(#[from] std::io::Error),
}
