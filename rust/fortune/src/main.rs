use std::fs;
use std::io;
use std::io::prelude::*;
use std::net::{TcpListener, TcpStream};
use std::path::Path;
use std::time::Duration;

use rand::seq::SliceRandom;

const ADDR: &str = "127.0.0.1:5000";
const FORTUNES: &str = "fortunes";
const REFRESH: Duration = Duration::from_secs(30);

fn main() {
    let fortunes = fortunes_from_file(FORTUNES).expect("Failed to read fortunes");

    eprintln!("Listening on http://{}", ADDR);
    let listener = TcpListener::bind(ADDR).expect("Failed to bind address");

    for incomming in listener.incoming() {
        let stream = match incomming {
            Err(e) => {
                eprintln!("Accept failed: {}", e);
                continue;
            }
            Ok(stream) => stream,
        };

        let peer_addr = stream.peer_addr().unwrap();
        eprintln!("Accepted connection from {}", peer_addr);
        handle_stream(stream, &fortunes)
            .unwrap_or_else(|e| eprintln!("Failed to handle stream: {}", e));
    }
}

/// Read fortunes from a fortunes text file.
fn fortunes_from_file<P: AsRef<Path>>(path: P) -> io::Result<Vec<String>> {
    let data = fs::read_to_string(path)?;

    let mut fortunes = Vec::new();
    for fortune in data.split("\n%\n") {
        fortunes.push(fortune.to_string());
    }

    Ok(fortunes)
}

/// Handle a single connection stream.
fn handle_stream(mut stream: TcpStream, fortunes: &[String]) -> io::Result<()> {
    let mut rng = rand::thread_rng();
    let picked_fortune = fortunes.choose(&mut rng).expect("No fortunes available");

    writeln!(
        stream,
        concat!(
            "HTTP/1.0 200 OK\r\n",
            "Content-Type: text/plain; charset=UTF-8\r\n",
            "Refresh: {}\r\n",
            "\r\n",
            "{}"
        ),
        REFRESH.as_secs(),
        picked_fortune
    )?;

    Ok(())
}

#[cfg(test)]
mod test {
    use std::io::Read;

    use super::*;

    #[test]
    fn test_fortunes_from_file() {
        let fortunes = fortunes_from_file(FORTUNES).unwrap();

        // Some assorted fortunes
        assert_eq!(fortunes[15], "To teach is to learn.");
        assert_eq!(
            fortunes[39],
            concat!(
                "Write a wise saying and your name will live forever.\n",
                "                -- Anonymous"
            )
        );
        assert_eq!(fortunes[98], "All rights reserved.");
    }

    #[test]
    fn test_handle_steam() {
        // Fixed fortune
        let fortunes = vec![String::from("Reply hazy, try again.")];

        // Server
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let local_addr = listener.local_addr().unwrap();

        std::thread::spawn(move || {
            let (stream, _) = listener.accept().unwrap();

            handle_stream(stream, &fortunes).unwrap();
        });

        // Client
        let mut client = TcpStream::connect(local_addr).unwrap();
        let mut buf = String::new();
        client.read_to_string(&mut buf).expect("Read failed");

        assert_eq!(
            buf,
            concat!(
                "HTTP/1.0 200 OK\r\n",
                "Content-Type: text/plain; charset=UTF-8\r\n",
                "Refresh: 30\r\n",
                "\r\n",
                "Reply hazy, try again.\n"
            )
        );
    }
}
