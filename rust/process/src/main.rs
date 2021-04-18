use std::net::Shutdown;
use std::os::unix::io::AsRawFd;
use std::os::unix::io::IntoRawFd;
use std::os::unix::net::UnixStream;
use std::os::unix::process::CommandExt;
use std::process::Command;
use std::io::prelude::*;

use nix::fcntl::{fcntl, FdFlag};
use nix::fcntl::FcntlArg::{F_GETFD, F_SETFD};

fn main() {
    // Create a bi-directional pipe using a Unix domain socket
    let (mut sock1, sock2) = UnixStream::pair().expect("Failed to create socket pair");

    // Start socat listening on socket
    let mut command = Command::new("socat")
        .args(&[format!("FD:{}", sock2.as_raw_fd()).as_str(), "STDOUT"])
        .pass_fd(sock2.as_raw_fd())
        .spawn()
        .expect("Failed to start process");

    // Send message
    sock1.write_all(b"Hello, world!\n").expect("Write failed");
    sock1.shutdown(Shutdown::Both).expect("Shutdown failed");

    // Wait for socat to exit
    let status = command.wait().expect("Wait failed");
    println!("{}", status);
}

trait PassFd {
    /// Pass file-descriptor to child process
    fn pass_fd<F: IntoRawFd>(&mut self, fd: F) -> &mut Command;
}

impl PassFd for Command {
    fn pass_fd<F: IntoRawFd>(&mut self, fd: F) -> &mut Command {
        let fd = fd.into_raw_fd();
        unsafe {
            self.pre_exec(move || {
                // Unset FD_CLOEXEC
                let mut flags = FdFlag::from_bits(fcntl(fd, F_GETFD).expect("Failed to get FD flags")).unwrap();
                flags.remove(FdFlag::FD_CLOEXEC);
                fcntl(fd, F_SETFD(flags)).expect("Failed to set FD flags");
                Ok(())
            })
        }
    }
}
