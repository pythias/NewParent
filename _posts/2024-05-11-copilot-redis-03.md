---
layout: post
title: "联手Copilot用Rust编写Redis - 第三章"
description: "联手Copilot用Rust编写的简化版Redis"
date: 2024-05-11

tags: ["AI", "Copilot", "Rust", "Redis"]
categories: blog

---

接[上回](/blog/2024/05/08/copilot-redis-02.html)，今天跑步189心率，现在还没缓过来。写个简单的。

## 任务

- 保持连接。
- 压测一下PING。

## 保持连接

**pythias**: 使用redis-cli连接发指令

```shell
(base) ➜  NewParent git:(master) ✗ redis-cli -p 7878
127.0.0.1:7878> ping
PONG
127.0.0.1:7878> ping
Error: Server closed the connection
not connected> 
```

**GitHub Copilot**: 看起来你的服务器在处理第二个 "ping" 命令时关闭了连接。这可能是因为你的 `handle_connection` 函数在处理完一个命令后就结束了，而不是继续等待新的命令。

你可以通过在 `handle_connection` 函数中添加一个循环来解决这个问题，使其能够处理多个命令。这个循环应该在客户端关闭连接时结束。

以下是修改后的 `handle_connection` 函数：

```rust
fn handle_connection(mut stream: TcpStream) -> Result<(), String> {
    let mut buffer = [0; 512];

    loop {
        match stream.read(&mut buffer) {
            Ok(0) => {
                // Connection was closed
                return Ok(());
            }
            Ok(_) => {
                let mut protocol = Protocol::new();
                protocol.parse(&buffer)?;
                let response = protocol.handle_command()?;

                stream.write(response.as_bytes()).unwrap();
                stream.flush().unwrap();
            }
            Err(e) => {
                return Err(e.to_string());
            }
        }
    }
}
```

这段代码会一直读取并处理命令，直到客户端关闭连接。如果在读取或处理命令时出现错误，它会返回一个错误。

## 压测PING

> 官方有一个工具`redis-benchmark`，可以用来测试redis的性能。

**pythias**: 使用`redis-benchmark`测试

```shell
(base) ➜  NewParent git:(master) ✗ redis-benchmark -h 127.0.0.1 -p 7878 -n 1000 -c 10 -t ping
WARNING: Could not fetch server CONFIG
PING_INLINE: rps=0.0 (overall: nan) avg_msec=nan (overall: nError: Server closed the connection
```

**GitHub Copilot**: 看起来你的服务器在处理 `redis-benchmark` 工具的并发请求时关闭了连接。这可能是因为你的服务器当前只能处理单个连接，而 `redis-benchmark` 工具会同时发起多个连接。

你需要修改你的服务器代码，使其能够处理多个并发连接。这可以通过为每个连接创建一个新的线程来实现。

以下是修改后的 `main` 函数：

```rust
use std::thread;

fn main() {
    let listener = TcpListener::bind("127.0.0.1:7878").unwrap();

    for stream in listener.incoming() {
        let stream = stream.unwrap();

        thread::spawn(|| {
            let _ = handle_connection(stream);
        });
    }
}
```

这段代码会为每个新的连接创建一个新的线程，这样每个连接都可以并行处理，而不会阻塞其他连接。

**pythias**: 挺好，可以同时连接了。但是还是相同的提示。`WARNING: Could not fetch server CONFIG`

**GitHub Copilot**: `redis-benchmark` 工具在运行测试之前会尝试获取 Redis 服务器的配置信息。这是通过发送 `CONFIG GET *` 命令来完成的。看起来你的服务器并没有实现 `CONFIG` 命令，所以 `redis-benchmark` 工具无法获取配置信息，因此显示了警告信息。

如果你想消除这个警告，你需要在你的服务器中实现 `CONFIG` 命令。但是，如果你只是想运行基本的性能测试，那么这个警告可以忽略，它不会影响 `redis-benchmark` 工具的基本功能。

如果你想实现 `CONFIG` 命令，你可以在 `handle_command` 函数中添加一个新的分支来处理这个命令。以下是一个简单的实现：

```rust
pub fn handle_command(&self) -> Result<String, String> {
    println!("Handling command: {:?}", self.result);

    match self.result.first() {
        Some(command) if command.to_uppercase() == "PING" => {
            Ok(Response::SimpleString("PONG".to_string()).to_string())
        }
        Some(command) if command.to_uppercase() == "CONFIG" => {
            Ok(Response::Array(vec![
                Response::BulkString("dbfilename".to_string()),
                Response::BulkString("dump.rdb".to_string()),
                // Add more configuration options here
            ]).to_string())
        }
        _ => Err(Response::Error("Unknown command".to_string()).to_string()),
    }
}
```

这个实现会返回一个包含一些配置选项的数组。你需要根据你的服务器的实际配置来修改这个数组。

**pythias**: 有错误

```
error[E0308]: mismatched types
  --> src/command/protocol.rs:96:42
   |
96 | ...   Response::BulkString("dbfilename".to_string()),
   |       -------------------- ^^^^^^^^^^^^^^^^^^^^^^^^ expected `Option<Vec<u8>>`, found `String`
   |       |
   |       arguments to this enum variant are incorrect
```

**GitHub Copilot**: `看起来你的 `Response::BulkString` 枚举变量期望一个 `Option<Vec<u8>>` 类型的参数，而不是 `String`。你需要将 `String` 转换为 `Vec<u8>`，然后将其包装在 `Some` 中。

以下是修改后的 `handle_command` 函数：

```rust
pub fn handle_command(&self) -> Result<String, String> {
    println!("Handling command: {:?}", self.result);

    match self.result.first() {
        Some(command) if command.to_uppercase() == "PING" => {
            Ok(Response::SimpleString("PONG".to_string()).to_string())
        }
        Some(command) if command.to_uppercase() == "CONFIG" => {
            Ok(Response::Array(vec![
                Response::BulkString(Some("dbfilename".to_string().into_bytes())),
                Response::BulkString(Some("dump.rdb".to_string().into_bytes())),
                // Add more configuration options here
            ]).to_string())
        }
        _ => Err(Response::Error("Unknown command".to_string()).to_string()),
    }
}
```

这段代码将 `String` 转换为 `Vec<u8>`，然后将其包装在 `Some` 中，以满足 `Response::BulkString` 的期望类型。

**pythias**: 可以了，但是卡住了，日志是`Handling command: ["CONFIG", "GET", "save"]`

**GitHub Copilot**: 看起来 `redis-benchmark` 工具正在尝试获取 `save` 配置选项，这是 Redis 服务器的一个配置选项，用于控制数据持久化的行为。你的服务器可能还没有实现这个配置选项。

你可以在 `handle_command` 函数中添加一个新的分支来处理 `CONFIG GET save` 命令。以下是一个简单的实现：

```rust
pub fn handle_command(&self) -> Result<String, String> {
    println!("Handling command: {:?}", self.result);

    match self.result.first() {
        Some(command) if command.to_uppercase() == "PING" => {
            Ok(Response::SimpleString("PONG".to_string()).to_string())
        }
        Some(command) if command.to_uppercase() == "CONFIG" => {
            if self.result.len() >= 3 && self.result[1].to_uppercase() == "GET" {
                match self.result[2].as_str() {
                    "save" => Ok(Response::Array(vec![
                        Response::BulkString(Some("900".to_string().into_bytes())),
                        Response::BulkString(Some("1".to_string().into_bytes())),
                        Response::BulkString(Some("300".to_string().into_bytes())),
                        Response::BulkString(Some("10".to_string().into_bytes())),
                        Response::BulkString(Some("60".to_string().into_bytes())),
                        Response::BulkString(Some("10000".to_string().into_bytes())),
                    ]).to_string()),
                    _ => Err(Response::Error("Unknown config option".to_string()).to_string()),
                }
            } else {
                Ok(Response::Array(vec![
                    Response::BulkString(Some("dbfilename".to_string().into_bytes())),
                    Response::BulkString(Some("dump.rdb".to_string().into_bytes())),
                    // Add more configuration options here
                ]).to_string())
            }
        }
        _ => Err(Response::Error("Unknown command".to_string()).to_string()),
    }
}
```

这个实现会返回一个包含 `save` 配置选项的数组。这个数组的值是 Redis 默认的 `save` 配置选项的值，你需要根据你的服务器的实际配置来修改这个数组。

**pythias**: CONFIG GET 指令能用了

```
(base) ➜  pythias git:(main) redis-cli -p 7878
127.0.0.1:7878> config get save
1) "900"
2) "1"
3) "300"
4) "10"
5) "60"
6) "10000"
127.0.0.1:7878>
```

但是`redis-benchmark`还是卡住了，是不是返回值里没有redis-benchmark需要的数据？

**GitHub Copilot**: `redis-benchmark` 工具在运行测试之前会尝试获取 Redis 服务器的一些配置信息，包括 `save`、`appendonly`、`appendfsync` 等。如果你的服务器没有实现这些配置选项，`redis-benchmark` 工具可能会卡住。

你可以在 `handle_command` 函数中添加更多的分支来处理这些配置选项。以下是一个扩展的实现：

```rust
pub fn handle_command(&self) -> Result<String, String> {
    println!("Handling command: {:?}", self.result);

    match self.result.first() {
        Some(command) if command.to_uppercase() == "PING" => {
            Ok(Response::SimpleString("PONG".to_string()).to_string())
        }
        Some(command) if command.to_uppercase() == "CONFIG" => {
            if self.result.len() >= 3 && self.result[1].to_uppercase() == "GET" {
                match self.result[2].as_str() {
                    "save" => Ok(Response::Array(vec![
                        Response::BulkString(Some("900".to_string().into_bytes())),
                        Response::BulkString(Some("1".to_string().into_bytes())),
                        Response::BulkString(Some("300".to_string().into_bytes())),
                        Response::BulkString(Some("10".to_string().into_bytes())),
                        Response::BulkString(Some("60".to_string().into_bytes())),
                        Response::BulkString(Some("10000".to_string().into_bytes())),
                    ]).to_string()),
                    "appendonly" => Ok(Response::BulkString(Some("no".to_string().into_bytes())).to_string()),
                    "appendfsync" => Ok(Response::BulkString(Some("everysec".to_string().into_bytes())).to_string()),
                    _ => Err(Response::Error("Unknown config option".to_string()).to_string()),
                }
            } else {
                Ok(Response::Array(vec![
                    Response::BulkString(Some("dbfilename".to_string().into_bytes())),
                    Response::BulkString(Some("dump.rdb".to_string().into_bytes())),
                    // Add more configuration options here
                ]).to_string())
            }
        }
        _ => Err(Response::Error("Unknown command".to_string()).to_string()),
    }
}
```

这个实现添加了 `appendonly` 和 `appendfsync` 配置选项。这些选项的值是 Redis 默认的值，你需要根据你的服务器的实际配置来修改这些值。

**pythias**: 还是卡着呢，卡在`Handling command: ["CONFIG", "GET", "save"]`，我所用 redis-benchmark 的版本是 7.2.1

> 它还在坚持，省略它的回答，再问一遍。

**pythias**: 还是卡着呢，是不是你弄错了？

**GitHub Copilot**: 对不起，我可能误解了你的问题。在Redis中，`CONFIG GET save`命令返回的是一个键值对列表，其中每个键值对都是一个自动保存的配置。键是字符串 "save"，值是一个表示自动保存配置的字符串，例如 "900 1 300 10 60 10000"。

你的代码应该返回一个类似的键值对列表。例如：

```rust
match self.result[2].as_str() {
    "save" => Ok(Response::Array(vec![
        Response::BulkString(Some("save".to_string().into_bytes())),
        Response::BulkString(Some("900 1 300 10 60 10000".to_string().into_bytes())),
    ]).to_string()),
    // ...
}
```

这个实现返回了一个键值对，键是 "save"，值是 "900 1 300 10 60 10000"。这表示Redis将在900秒内如果有1次更改，或者300秒内如果有10次更改，或者60秒内如果有10000次更改，就会自动保存。你需要根据你的服务器的实际配置来修改这个值。

**pythias**: 还是没有进行下一步操作，你再确认一下redis-benchmark的具体流程，看看哪儿有错。

> 它会到了最开始的数组返回，然后卡住了。

**pythias**: 你又会到开头，假如这个redis不进行保存。那么如何返回？

**GitHub Copilot**: 如果你的 Redis 服务器不进行自动保存，那么 `CONFIG GET save` 命令应该返回一个空的数组。你可以修改你的代码来实现这个行为：

```rust
match self.result[2].as_str() {
    "save" => Ok(Response::Array(vec![]).to_string()),
    // ...
}
```

这个实现返回了一个空的数组，表示没有任何自动保存的配置。

> 它还是没搞定，看来需要让它从头读一下协议和配置文件的内容。等下回`回到协议本身`

## 其他章节

- [开始](/blog/2024/04/30/copilot-redis.html)
- [第一章](/blog/2024/05/01/copilot-redis-01.html)
- [第二章](/blog/2024/05/08/copilot-redis-02.html)
- 第三章
- [第四章](/blog/2024/05/17/copilot-redis-04.html)
- [第五章](/blog/2024/06/12/copilot-redis-05.html)