# Getting Started 🚀

## Installing Rust

Before you can start writing Rust code, you must have the Rust toolchain installed.

The easiest way to do so is using [`rustup`](https://rust-lang.github.io/rustup/) to keep the toolchain up to date. Follow the [Rust install instructions](https://www.rust-lang.org/tools/install) on the Rust website.

```
$ rustup --quiet update
info: syncing channel updates for 'stable-x86_64-unknown-linux-gnu'
info: checking for self-updates

  stable-x86_64-unknown-linux-gnu unchanged - rustc 1.53.0 (53cb7b09b 2021-06-17)

info: cleaning up downloads & tmp directories
```

**Note:** If installing Rust naively on Windows (i.e. not WSL), you'll need to install the [Microsoft C++ build tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) first.

If everything is working correctly, you should be able to check the version of the Rust compiler ([`rustc`](https://doc.rust-lang.org/rustc)) installed:

```
$ rustc --version
rustc 1.53.0 (53cb7b09b 2021-06-17)
```

## Creating a new project

While it's possible to compile code using rustc directly, it's much easier to use Rust's built-in package manager [Cargo](https://doc.rust-lang.org/cargo/).

Let's use Cargo to create a new project:

```
$ cargo new fortune
     Created binary (application) `fortune` package
$ tree -a -I .git fortune/
fortune/
├── .gitignore
├── Cargo.toml
└── src
    └── main.rs

1 directory, 3 files
```

As you can see, Cargo has created a skeleton binary package with the following files:
- `Cargo.toml` – Package configuration
- `.gitignore` – A .gitignore file tuned for Rust projects
- `src/main.rs` – Some Rust code

Let's try running the project!

```
$ cd fortune
$ cargo run
   Compiling fortune v0.1.0 (/tmp/fortune)
    Finished dev [unoptimized + debuginfo] target(s) in 0.44s
     Running `target/debug/fortune`
Hello, world!
```

Cargo compiled the Rust code and executed it for us. Nice!
We're ready to start coding!

## Hello, world!

Usually one of the first activities when learning a new programming language is to write a ["Hello, world!" program](https://en.wikipedia.org/wiki/%22Hello,_World!%22_program), but Cargo is so efficient it's done that for us!

Let's take a look at what it produced.

`src/main.rs`

```rust
fn main() {
    println!("Hello, world!");
}
```

Here we can see the structure of a basic Rust program:

- On line 1, we declare a function called main that takes no arguments and returns no results
- On line 2, we use the [`println!` macro](https://doc.rust-lang.org/std/macro.println.html) to print some text to [`stdout`](https://en.wikipedia.org/wiki/stdout)

### ✔️ Activity 1

Modify the "Hello, world!" program to prompt for and then print your name.

You can read a line of input using the following code:

```rust
use std::io::stdin;

let mut line = String::new();
stdin().read_line(&mut line).unwrap();
```
