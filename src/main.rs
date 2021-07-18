use std::fs;
use std::io;
use std::path::Path;

const FORTUNES: &str = "fortunes";

fn main() {
    let fortunes = fortunes_from_file(FORTUNES).expect("Failed to read fortunes");

    println!("{}", fortunes[0]);
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

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_fortunes_from_file() {
        let fortunes = fortunes_from_file(FORTUNES).unwrap();

        assert_eq!(fortunes[15], "To teach is to learn.");
        assert_eq!(fortunes[39], "Write a wise saying and your name will live forever.\n                -- Anonymous");
        assert_eq!(fortunes[98], "All rights reserved.");
    }
}