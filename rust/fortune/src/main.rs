use std::fs;
use std::io;
use std::io::prelude::*;
use std::io::BufReader;
use std::net::{TcpListener, TcpStream};
use std::path::Path;
use std::time::Duration;

use rand::seq::SliceRandom;

const ADDR: &str = "127.0.0.1:5000";
const FORTUNES: &str = "fortunes";
const REFRESH: Duration = Duration::from_secs(30);
const MAX_READ: u64 = 1024;

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

    let reader = BufReader::new(stream.try_clone()?);

    let mut line = String::new();
    reader.take(MAX_READ).read_line(&mut line)?;

    let request: Vec<&str> = line.trim_end().splitn(3, " ").collect();
    if request.len() != 3 || request[0] != "GET" {
        return Ok(());
    }

    match request[1] {
        "/fortune.svg" => {
            // SVG fortune
            writeln!(
                stream,
                concat!(
                    "HTTP/1.0 200 OK\r\n",
                    "Content-Type: image/svg+xml; charset=UTF-8\r\n",
                    "\r\n",
                    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n",
                    "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xhtml=\"http://www.w3.org/1999/xhtml\" viewBox=\"0 0 500 125\">\n",
                    "  <switch>\n",
                    "    <foreignObject x=\"0\" y=\"0\" width=\"100%\" height=\"125px\">\n",
                    "      <xhtml:div style=\"display: flex; height: 125px; justify-content: center; align-items: center;\">\n",
                    "        <xhtml:span style=\"padding: 1em; text-align: justify; font-size: 10pt; font-family: Segoe Print, Bradley Hand ITC, sans-serif; color: #000; white-space: pre-wrap;\"><![CDATA[{}]]></xhtml:span>\n",
                    "      </xhtml:div>\n",
                    "    </foreignObject>\n",
                    "    <text x=\"50%\" y=\"50%\" text-anchor=\"middle\">Your SVG viewer cannot display HTML</text>\n",
                    "  </switch>\n",
                    "</svg>\n"
                ),
                picked_fortune
            )?;
        },
        _ => {
            // Standard text fortune
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
        },
    }

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
        assert_eq!(fortunes[97], "All rights reserved.");
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
