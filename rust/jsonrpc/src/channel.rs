//! Channel for sending/receiving JSONRPC frames

use tokio::io::{self, AsyncBufReadExt, AsyncWriteExt};
use tokio::net::TcpStream;

use crate::message::Message;

const TERMINATOR: u8 = b'\n';

pub struct Channel {
    stream: io::BufStream<TcpStream>,
}

impl Channel {
    pub fn new(socket: TcpStream) -> io::Result<Self> {
        let stream = io::BufStream::new(socket);

        Ok(Channel { stream })
    }

    pub async fn send_frame(&mut self, message: Message) -> crate::Result<()> {
        let mut json = serde_json::to_vec(&message)?;
        json.push(TERMINATOR);

        self.stream.write_all(&json).await?;
        self.stream.flush().await?;

        Ok(())
    }

    pub async fn receive_frame(&mut self) -> crate::Result<Message> {
        let mut buf = Vec::with_capacity(1024);
        self.stream.read_until(TERMINATOR, &mut buf).await?;

        let message: Message = serde_json::from_slice(&buf)?;

        Ok(message)
    }
}
