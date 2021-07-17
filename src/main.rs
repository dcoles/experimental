use std::io::Write;
use std::process::Command;

const FORTUNE: &str = "fortune";

fn main() {
    println!("[FORTUNE COOKIE]");
    println!("{}", fortune());
}

/// Get a fortune cookie.
fn fortune() -> String {
    let output = Command::new(FORTUNE)
        .arg("-s")  // Short fortunes only
        .output()
        .expect("Failed to get fortune");

        String::from_utf8(output.stdout).expect("Failed to decode output")
}
