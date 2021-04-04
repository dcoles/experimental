use serde_json::Value;
use tokio::net::{TcpStream, ToSocketAddrs};

use crate::Error;
use crate::channel::Channel;
use crate::message::{Message, Params, VERSION};

pub struct Client {
    channel: Channel,
    request_counter: u64,
}

impl Client {
    pub async fn call(&mut self, method: &str, params: Option<Params>) -> crate::Result<Option<Value>> {
        let request_id = self.request_counter;
        self.request_counter += 1;

        let request = Message::make_request(method, params, Some(request_id.into()));
        self.channel.send_frame(request).await?;

        let message = self.channel.receive_frame().await?;
        if message.version() != VERSION {
            return Err(Error::Protocol(format!("Received message for unsupported version: {}", message.version())));
        }

        if message.is_request() {
            return Err(Error::Protocol(format!("Received unexpected request: {:?}", message.request().unwrap())));
        }

        let response = match message.response() {
            None => return Err(Error::Protocol("Received non-response type".to_string())),
            Some(response) => response,
        };

        if response.id.as_u64() != Some(request_id) {
            return Err(Error::Protocol(format!("Received unexpected response ID: {:?}", response.id)));
        }

        return match response.error {
            Some(err) => Err(Error::RPC(err)),
            None => Ok(response.result),
        }
    }
}

pub async fn connect<A: ToSocketAddrs>(addr: A) -> crate::Result<Client> {
    let stream = TcpStream::connect(addr).await?;
    let channel = Channel::new(stream)?;

    Ok(Client { channel, request_counter: 0 })
}
