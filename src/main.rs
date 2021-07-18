use std::fs;
use std::io;
use std::io::Write;
use std::net::TcpListener;
use std::net::TcpStream;
use std::path::Path;

use rand::seq::SliceRandom;

const ADDR: &str = "127.0.0.1:5000";
const FORTUNES: &str = "fortunes";

fn main() {
    let fortunes = fortunes_from_file(FORTUNES).expect("Failed to read fortunes");

    eprintln!("Listening on {}", ADDR);
    let listener = TcpListener::bind(ADDR).expect("Failed to bind address");

    for incomming in listener.incoming() {
        let stream = match incomming {
            Err(e) => {
                eprintln!("Accept failed: {}", e);
                continue;
            },
            Ok(stream) => stream,
        };

        let peer_addr = stream.peer_addr().expect("Failed to get peer address");
        eprintln!("Accepted connection from {}", peer_addr);
        handle_stream(stream, &fortunes);
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
fn handle_stream(mut stream: TcpStream, fortunes: &[String]) {
    let mut rng = rand::thread_rng();
    let picked_fortune = fortunes.choose(&mut rng).expect("No fortunes available");

    writeln!(stream, "{}", picked_fortune).expect("Write failed");
}

#[cfg(test)]
mod test {
    use std::io::Read;

    use super::*;

    #[test]
    fn test_fortunes_from_file() {
        let fortunes = fortunes_from_file(FORTUNES).unwrap();

        assert_eq!(fortunes[15], "To teach is to learn.");
        assert_eq!(fortunes[39], "Write a wise saying and your name will live forever.\n                -- Anonymous");
        assert_eq!(fortunes[98], "All rights reserved.");
    }

    #[test]
    fn test_handle_steam() {
        let fortunes = vec![String::from("Reply hazy, try again.")];

        let listener = TcpListener::bind("127.0.0.1:0").expect("Failed to bind address");
        let local_addr = listener.local_addr().expect("Failed to get local address");

        std::thread::spawn(move || {
            let (stream, _) = listener.accept().expect("Failed to accept connection");

            handle_stream(stream, &fortunes);
        });

        let mut client = TcpStream::connect(local_addr).unwrap();
        let mut buf = String::new();
        client.read_to_string(&mut buf).expect("Read failed");

        assert_eq!(buf, "Reply hazy, try again.\n");
    }
}