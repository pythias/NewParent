---
layout: post
title: "联手Copilot用Rust编写Redis"
description: "联手Copilot用Rust编写的简化版Redis"
date: 2024-04-30

tags: ["AI", "Copilot", "Rust", "Redis"]
categories: blog

---

## 起源

从第一次用ChatGPT到现在已经过了一年多了，Copilot 也在慢慢改变我们的编程方式。当初学 Rust 的时候就想着要不要写一个简化版的 Redis，现在正好可以用 Copilot 来帮助我们完成这个任务。

## 基本设想

- 全程使用 Copilot 辅助。
- 记录下所有交互过程。

功能要求：

- 兼容 Redis 协议。
- 实现包括 String, Hash, List, Set, Sorted Set 等数据结构及其指令。
- 单进程数据安全。
- 不支持持久化、集群、主从复制、数据库等功能。

## 迈出第一步

- Me:

use rust create a tcp server

- Copilot:

Here is a basic example of a TCP server in Rust:

```rust
use std::io::prelude::*;
use std::net::TcpListener;
use std::net::TcpStream;

fn main() {
    let listener = TcpListener::bind("127.0.0.1:7878").unwrap();

    for stream in listener.incoming() {
        let stream = stream.unwrap();

        handle_connection(stream);
    }
}

fn handle_connection(mut stream: TcpStream) {
    let mut buffer = [0; 512];

    stream.read(&mut buffer).unwrap();

    println!("Request: {}", String::from_utf8_lossy(&buffer[..]));
}
```

his code creates a TCP server that listens on localhost at port 7878. When a connection is made, it reads the incoming data into a buffer and prints it out.

## 让它跑起来

- Me:

how to run main.rs

- Copilot:

To run the `main.rs` file in Rust, you need to use the `cargo run` command in the terminal. Here's how you do it:

1. Open the terminal in Visual Studio Code by going to `View -> Terminal` or by pressing `Control + backtick (``)`.

2. Navigate to the directory containing your `main.rs` file. You can do this using the `cd` command. For example, if your `main.rs` file is in a directory named `my_project`, you would type `cd my_project`.

3. Once you're in the correct directory, type `cargo run` and press `Enter`. This will compile and run your `main.rs` file.

Here's what the commands look like:

```bash
cd path_to_your_project
cargo run
```

Replace `path_to_your_project` with the actual path to your project.

pythias: error: could not find `Cargo.toml` in `./rust/ai-redis` or any parent directory

GitHub Copilot: The error message you're seeing indicates that the `cargo` command can't find a `Cargo.toml` file in your current directory or any parent directory. The `Cargo.toml` file is necessary for managing Rust packages.

Here's how you can create a new `Cargo.toml` file:

1. Navigate to the root directory of your project (the directory that should contain `Cargo.toml`).

2. Run the command `cargo init` in your terminal. This will create a new `Cargo.toml` file and a `src` directory if they don't already exist.

3. Move your `main.rs` file into the `src` directory.

4. Now you should be able to run `cargo run` from the root directory of your project.

Here are the commands:

```bash
cd path_to_your_project
cargo init
mv main.rs src/
cargo run
```

Replace `path_to_your_project` with the actual path to your project.

## 发现Cargo没有安装

- Me:

error: could not find `Cargo.toml` in `./rust/ai-redis` or any parent directory

- Copilot:

The error message you're seeing indicates that the `cargo` command can't find a `Cargo.toml` file in your current directory or any parent directory. The `Cargo.toml` file is necessary for managing Rust packages.

Here's how you can create a new `Cargo.toml` file:

1. Navigate to the root directory of your project (the directory that should contain `Cargo.toml`).

2. Run the command `cargo init` in your terminal. This will create a new `Cargo.toml` file and a `src` directory if they don't already exist.

3. Move your `main.rs` file into the `src` directory.

4. Now you should be able to run `cargo run` from the root directory of your project.

Here are the commands:

```bash
cd path_to_your_project
cargo init
mv main.rs src/
cargo run
```

Replace `path_to_your_project` with the actual path to your project.

> 点评

此处它有错误，`cargo init`时会自动根据 `main.rs` 的位置生成`Cargo.toml`，不需要手动移动`main.rs`。但是使用`src`目录更符合Rust的项目结构。所以可以这么操作

```bash
cd path_to_your_project
mkdir src
mv main.rs src/
cargo init
```

我试着跟它交流一下这个问题

- Me:

cargo run
   Compiling ai-redis v0.1.0 (./rust/ai-redis)
error: couldn't read main.rs: No such file or directory (os error 2)

error: could not compile `ai-redis` (bin "ai-redis") due to 1 previous error

- Copilot:

The error message indicates that the Rust compiler cannot find the `main.rs` file in the expected location. 

Ensure that your `main.rs` file is located in the `src` directory of your project. The structure should look like this:

```
your_project
├── Cargo.toml
└── src
    └── main.rs
```

If your `main.rs` file is not in the `src` directory, move it there. You can use the `mv` command in the terminal to move files:

```bash
mv path_to_your_main.rs src/main.rs
```

Replace `path_to_your_main.rs` with the actual path to your `main.rs` file.

After moving `main.rs` to the `src` directory, try running `cargo run` again.

- Me:

main.rs已经在src目录下

- Copilot:

The `Cargo.toml` file is incorrectly pointing to `main.rs` in the root directory. Since you've mentioned that `main.rs` is already in the `src` directory, you need to update the `path` under `[[bin]]` to point to `src/main.rs`.

Here's how your `Cargo.toml` should look:

```toml
[package]
name = "ai-redis"
version = "0.1.0"
edition = "2021"

# See more keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html

[dependencies]

[[bin]]
name = "ai-redis"
path = "src/main.rs"
```

After updating `Cargo.toml`, try running `cargo run` again.

> 点评

我问得不对，它没意识到之前处理顺序问题，导致`main.rs`在`src`目录下，但是`Cargo.toml`中的`path`字段指向了错误的位置。第二次提交时它知道了。但它还有几个地方有错，比如配置文件它用了`plaintext`没用`toml`；比如 `[[bin]]` 其实可以省略，因为默认就是`src/main.rs`。

## 总结

Copilot 在这个过程中帮助我完成了一个简单的TCP Server的创建，但是在配置Cargo时有一些问题。我发现Copilot在处理问题时，有时候会忽略之前的问题，导致后续的问题无法解决。但是总体来说，Copilot还是一个很好的工具，可以帮助我们快速完成一些简单的任务。

## 其他章节

- [开始](/blog/2024/04/30/copilot-redis.html)
- [第一章](/blog/2024/05/01/copilot-redis-01.html)
