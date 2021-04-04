use std::collections::HashMap;

use serde_json::Value;
use tokio::net::{TcpListener, ToSocketAddrs};
use log::{debug, info, warn};

use crate::channel::Channel;
use crate::message::{Error, Message, Params, VERSION};

pub type Handler = dyn Fn(Option<&Params>) -> Option<Value>;

pub struct Server {
    listener: TcpListener,
    handlers: HashMap<String, Box<Handler>>,
}

pub async fn listen<A: ToSocketAddrs>(addr: A, handlers: HashMap<String, Box<Handler>>) -> crate::Result<Server> {
    let listener = TcpListener::bind(addr).await?;

    Ok(Server { listener, handlers })
}

impl Server {
    pub async fn run(&mut self) -> crate::Result<()> {
        loop {
            let (stream, peer) = self.listener.accept().await?;
            info!("Received connection from {}", peer);
            let mut channel = Channel::new(stream)?;

            let message = channel.receive_frame().await?;

            if message.version() != VERSION {
                warn!("Unexpected version: {}", message.version());
                continue;
            }

            if !message.is_request() {
                warn!("Unexpected message type");
                continue;
            }

            let request = message.request().unwrap();
            debug!("> {:?}", request);

            if request.id.is_none() {
                warn!("Unexpected notification");
                continue;
            }

            let request_id = request.id.unwrap();

            let response = if let Some(handler) = self.handlers.get_mut(&request.method) {
                let result = handler(request.params.as_ref());
                Message::make_response(result, request_id)
            } else {
                warn!("Method not found: {}", request.method);
                Message::make_error_response(Error::method_not_found(), request_id)
            };

            channel.send_frame(response).await?
        }
    }
}
