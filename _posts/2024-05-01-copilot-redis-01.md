---
layout: post
title: "联手Copilot用Rust编写Redis - 第一章"
description: "联手Copilot用Rust编写的简化版Redis"
date: 2024-05-01

tags: ["AI", "Copilot", "Rust", "Redis"]
categories: blog

---

接[上回](/blog/2024/04/30/copilot-redis.html)，我们继续用 Copilot 辅助编写 Redis 的简化版。今天是五一，祝所有打工人节日快乐！

## 任务

- 实现简单的 `Redis` 协议解析。
- 实现 `Ping/Pong` 指令。

## 开始

**pythias**: 我们已经完成了一个简单的TCPServer，现在我们需要解析Redis协议。RESP3的文档是 https://github.com/redis/redis-specifications/blob/master/protocol/RESP3.md ，你可以看一下。如果你已经了解 RESP3，请回答"已了解"

**GitHub Copilot**: "已了解"

**pythias**: OK，那么现在开始写解析器，为了后续编码方便，我们需要调整一下代码结构，目前我们只有一个 main.rs 文件，你有什么建议吗？

**GitHub Copilot**: 对于大型项目，建议将代码分解为多个模块，每个模块都在其自己的文件中。这样可以使代码更易于管理和理解。以下是一种可能的组织结构：

1. `main.rs`: 主程序入口点，处理程序启动和初始化。
2. `server.rs`: 包含服务器相关的代码，如启动服务器，接收连接等。
3. `client.rs`: 包含客户端处理的代码，如读取和写入数据等。
4. `protocol.rs`: 包含解析和生成RESP3协议的代码。
5. `command.rs`: 包含处理Redis命令的代码。

这样，每个文件都有明确的职责，使得代码更易于维护和扩展。

**pythias**: 你的建议很好，我们按照你的建议来组织代码。首先，我们创建一个新的文件 `protocol.rs`，然后在 `main.rs` 中引入它。你可以帮我写一下 `protocol.rs` 的内容吗？

当然可以。在 `protocol.rs` 文件中，我们首先定义一个 `Protocol` 结构体，它将包含解析 RESP3 协议所需的状态。然后，我们可以添加一个 `new` 函数来创建一个新的 `Protocol` 实例，以及一个 `parse` 函数来解析输入数据。

这是一个基本的 `protocol.rs` 文件的示例：

```rust
pub struct Protocol {
    // 这里可以添加你需要的字段
}

impl Protocol {
    pub fn new() -> Self {
        Protocol {
            // 初始化字段
        }
    }

    pub fn parse(&mut self, data: &[u8]) -> Result<(), String> {
        // 在这里实现解析逻辑
        Ok(())
    }
}
```

然后，在 `main.rs` 文件中，你可以这样引入 `protocol` 模块：

```rust
mod protocol;

fn main() {
    let mut protocol = protocol::Protocol::new();
    // ...
}
```

请注意，这只是一个基本的框架，你需要根据 RESP3 协议的具体要求来实现 `parse` 函数。

**pythias**: 谢谢你的帮助，我会继续完善 `protocol.rs` 文件。接下来，我们将在 `protocol.rs` 中实现 RESP3 协议的解析逻辑。

**GitHub Copilot**: 很好，如果你在实现 RESP3 协议解析逻辑时遇到任何问题，或者需要帮助，随时向我询问。

## 协议

**pythias**: 你已经对RESP3有一定了解，它包括多种类型，每种类型有不同的开头和组织方式。我们先实现一个简单的解析器，只解析简单的字符串类型。你可以帮我写一下吗？

**GitHub Copilot**: 当然可以。在 RESP3 协议中，简单字符串以 '+' 开头，后跟字符串内容，最后以 '\r\n' 结束。我们可以在 `Protocol` 结构体中添加一个 `parse_simple_string` 方法来处理这种类型。

这是一个基本的实现：

```rust
impl Protocol {
    // ...

    pub fn parse_simple_string(&mut self, data: &[u8]) -> Result<String, String> {
        let data_str = std::str::from_utf8(data).map_err(|_| "Invalid UTF-8 sequence")?;
        if !data_str.starts_with('+') {
            return Err("Not a simple string".to_string());
        }

        let end = data_str.find("\r\n").ok_or("No end of line")?;
        let content = &data_str[1..end];

        Ok(content.to_string())
    }
}
```

这个函数首先检查输入数据是否以 '+' 开头，然后查找 '\r\n'。如果找到，它将返回字符串的内容。如果任何检查失败，它将返回一个错误。

**pythias**: 需要根据不同类型进行解析，把`pub fn parse(&mut self, data: &[u8]) -> Result<(), String>`完善一下。

**GitHub Copilot**: 当然可以。在 `parse` 函数中，我们可以首先检查输入数据的第一个字符，然后根据它调用相应的解析函数。在这个例子中，我们只有 `parse_simple_string` 函数，所以我们只检查 '+' 字符。

这是一个基本的实现：

```rust
impl Protocol {
    // ...

    pub fn parse(&mut self, data: &[u8]) -> Result<(), String> {
        if data.is_empty() {
            return Err("Empty input".to_string());
        }

        match data[0] as char {
            '+' => {
                let result = self.parse_simple_string(data)?;
                println!("Parsed simple string: {}", result);
            }
            _ => return Err("Unknown type".to_string()),
        }

        Ok(())
    }

    // ...
}
```

这个函数首先检查输入数据是否为空。然后，它检查第一个字符，如果是 '+'，它将调用 `parse_simple_string` 函数。如果解析成功，它将打印解析的字符串。如果第一个字符是未知类型，它将返回一个错误。

**pythias**: 好的，现在我们把Protocol的解析集成到Server的`handle_connection`里，看是否能正常运作。

**GitHub Copilot**: 好的，我们可以在 `handle_connection` 函数中创建一个 `Protocol` 实例，并使用它来解析从客户端接收到的数据。这是一个基本的实现：

在 `server.rs` 文件中：

```rust
use crate::protocol::Protocol;

// ...

fn handle_connection(&mut self, stream: TcpStream) {
    let mut protocol = Protocol::new();

    // ...

    let mut buffer = [0; 512];
    stream.read(&mut buffer).unwrap();

    match protocol.parse(&buffer) {
        Ok(_) => println!("Successfully parsed message"),
        Err(e) => eprintln!("Failed to parse message: {}", e),
    }

    // ...
}
```

这个函数首先创建一个 `Protocol` 实例，然后读取从客户端接收到的数据到缓冲区。然后，它使用 `Protocol::parse` 函数来解析数据。如果解析成功，它将打印一条消息。如果解析失败，它将打印一个错误消息。

**pythias**: how can I use echo & nc to test

**GitHub Copilot**: You can use `echo` and `nc` (netcat) to send a simple string to your server. Here's how you can do it:

1. Open a terminal and start your server.

2. Open another terminal and use the following command to send a simple string to your server:

```bash
echo -e "+OK\r\n" | nc localhost 7878
```

This command will send the string "+OK\r\n" to your server running on localhost at port 7878. The `-e` option in `echo` command enables interpretation of backslash escapes, which allows us to use "\r\n" to represent a carriage return and a line feed.

Your server should receive this string and parse it using the `Protocol::parse` function.

> 执行 `cargo run` 启动服务器，然后在另一个终端执行 `echo -e "+OK\r\n" | nc localhost 7878` 发送字符串到服务器。

```bash
➜  ai-redis git:(master) ✗ cargo run
   Compiling ai-redis v0.1.0 (/mnt/e/work/github/ai-redis)
    Finished dev [unoptimized + debuginfo] target(s) in 1.68s
     Running `target/debug/ai-redis`
Parsed simple string: OK
Successfully parsed message
```

## 指令解析

**pythias**: 通过阅读RESP3的文档，我们了解到其实一个指令是多个基础类型的集合 `<aggregate-type-char><numelements><CR><LF> ... numelements other types ...`，比如PING指令就是 `*1\r\n$4\r\nPING\r\n`。为此我们需要修改之前的解析器，你可以帮我写一下吗？

**GitHub Copilot**: 首先，我们需要在 `Protocol` 结构体中添加一个字段来存储解析的结果。然后，我们需要修改 `parse` 方法以处理聚合类型。我们还需要添加一个新的方法 `parse_aggregate` 来解析聚合类型的数据。

以下是修改后的代码：

```rust
pub struct Protocol {
    result: Vec<String>, // 添加一个字段来存储解析的结果
}

impl Protocol {
    pub fn new() -> Self {
        Protocol {
            result: Vec::new(), // 初始化字段
        }
    }

    pub fn parse(&mut self, data: &[u8]) -> Result<(), String> {
        if data.is_empty() {
            return Err("Empty input".to_string());
        }

        match data[0] as char {
            '*' => {
                self.parse_aggregate(data)?; // 处理聚合类型
            }
            '+' => {
                let result = self.parse_simple_string(data)?;
                println!("Parsed simple string: {}", result);
            }
            _ => return Err("Unknown type".to_string()),
        }
        
        Ok(())
    }

    pub fn parse_aggregate(&mut self, data: &[u8]) -> Result<(), String> {
        let data_str = std::str::from_utf8(data).map_err(|_| "Invalid UTF-8 sequence")?;
        if !data_str.starts_with('*') {
            return Err("Not an aggregate type".to_string());
        }

        let end = data_str.find("\r\n").ok_or("No end of line")?;
        let num_elements: usize = data_str[1..end].parse().map_err(|_| "Invalid number of elements")?;

        let mut start = end + 2; // Skip "\r\n"
        for _ in 0..num_elements {
            let end = data_str[start..].find("\r\n").ok_or("No end of line")?;
            let element = &data_str[start..start+end];
            self.result.push(element.to_string());
            start += end + 2; // Skip "\r\n"
        }

        Ok(())
    }

    // ... 其他方法 ...
}
```

这段代码首先检查输入数据的第一个字符是否为 '*'，如果是，则调用 `parse_aggregate` 方法来解析聚合类型的数据。`parse_aggregate` 方法首先获取元素的数量，然后解析每个元素，并将其添加到结果中。

> 执行 `cargo run` 启动服务器，然后在另一个终端执行 `echo -e "*1\r\n$4\r\nPING\r\n" | nc localhost 7878` 发送字符串到服务器。

```bash
   Compiling ai-redis v0.1.0 (/mnt/e/work/github/ai-redis)
    Finished dev [unoptimized + debuginfo] target(s) in 1.90s
     Running `target/debug/ai-redis`
Successfully parsed message
```

**pythias**: 很好，我们已经实现了简单的 RESP3 协议解析器。接下来，我们根据不同的指令进行不同的处理，首先我们先实现 `PING` 指令

**GitHub Copilot**: 好的，我们可以在 `Protocol` 结构体中添加一个 `handle_command` 方法来处理 `PING` 指令。这个方法将检查解析的结果是否为 `PING`，如果是，它将返回 `PONG`。

这是一个简单的实现：

```rust
impl Protocol {
    // ...

    pub fn handle_command(&self) -> Result<String, String> {
        if self.result.is_empty() {
            return Err("No command to handle".to_string());
        }

        match self.result[0].as_str() {
            "PING" => Ok("PONG".to_string()),
            _ => Err("Unknown command".to_string()),
        }
    }
}
```

在这个实现中，我们首先检查 `result` 是否为空。如果为空，我们返回一个错误，表示没有命令可以处理。然后，我们检查 `result` 的第一个元素是否为 `PING`。如果是，我们返回 `PONG`。如果不是，我们返回一个错误，表示命令未知。

**pythias**: 这个 handle_command 写在哪个地方，parse 方法还是 parse_aggergate 里？

**GitHub Copilot**: `handle_command` 应该是一个单独的方法，不应该写在 `parse` 或 `parse_aggregate` 方法里。这是因为 `parse` 和 `parse_aggregate` 的职责是解析输入的数据，而 `handle_command` 的职责是处理解析后的结果。

你可以在 `parse` 方法之后添加 `handle_command` 方法。这样，你可以先调用 `parse` 方法解析输入的数据，然后调用 `handle_command` 方法处理解析后的结果。

这是一个可能的实现：

```rust
impl Protocol {
    // ...

    pub fn parse(&mut self, data: &[u8]) -> Result<(), String> {
        // ...
    }

    pub fn parse_aggregate(&mut self, data: &[u8]) -> Result<(), String> {
        // ...
    }

    pub fn handle_command(&self) -> Result<String, String> {
        if self.result.is_empty() {
            return Err("No command to handle".to_string());
        }

        match self.result[0].as_str() {
            "PING" => Ok("PONG".to_string()),
            _ => Err("Unknown command".to_string()),
        }
    }
}
```

在这个实现中，你可以这样使用 `Protocol`：

```rust
let mut protocol = Protocol::new();
protocol.parse(data)?;
let response = protocol.handle_command()?;
```

**pythias**: 执行时出现了语法错误

```bash
error[E0277]: the `?` operator can only be used in a function that returns `Result` or `Option` (or another type that implements 
`FromResidual`)
  --> src/main.rs:32:45
   |
19 | fn handle_connection(mut stream: TcpStream) {
   | ------------------------------------------- this function should return `Result` or `Option` to accept `?`
...
32 |     let response = protocol.handle_command()?;
   |                                             ^ cannot use the `?` operator in a function that returns `()`
   |
   = help: the trait `FromResidual<Result<Infallible, String>>` is not implemented for `()`

For more information about this error, try `rustc --explain E0277`.
error: could not compile `ai-redis` (bin "ai-redis") due to 1 previous error
```

**GitHub Copilot**: 这个错误是因为你在一个返回类型为 `()` 的函数中使用了 `?` 操作符。`?` 操作符用于处理 `Result` 或 `Option` 类型的错误，如果函数返回类型不是 `Result` 或 `Option`，则不能使用 `?` 操作符。

你需要将 `handle_connection` 函数的返回类型改为 `Result<(), String>`，这样就可以在函数中使用 `?` 操作符了。同时，你需要在函数的最后返回 `Ok(())` 表示函数成功执行。

这是修改后的 `handle_connection` 函数：

```rust
fn handle_connection(mut stream: TcpStream) -> Result<(), String> {
    let mut buffer = [0; 512];
    stream.read(&mut buffer).unwrap();

    let mut protocol = Protocol::new();
    protocol.parse(&buffer)?;
    let response = protocol.handle_command()?;

    stream.write(response.as_bytes()).unwrap();
    stream.flush().unwrap();

    Ok(())
}
```

在这个函数中，我们首先读取 `stream` 中的数据到 `buffer` 中，然后创建一个新的 `Protocol`，并使用 `buffer` 中的数据调用 `parse` 方法。然后，我们调用 `handle_command` 方法处理解析后的结果，并将结果写入 `stream` 中。最后，我们返回 `Ok(())` 表示函数成功执行。

> 执行 `cargo run` 启动服务器，然后在另一个终端执行 `echo -e "*1\r\n$4\r\nPING\r\n" | nc localhost 7878` 发送字符串到服务器。

```bash
   Compiling ai-redis v0.1.0 (/mnt/e/work/github/ai-redis)
    Finished dev [unoptimized + debuginfo] target(s) in 1.90s
     Running `target/debug/ai-redis`
```

**pythias**: 经过 `echo -e "*1\r\n$4\r\nPING\r\n" | nc localhost 7878` 测试收不到信息，请帮忙添加DEBUG信息

**GitHub Copilot**: 你可以使用 `println!` 宏在 Rust 中添加调试信息。这个宏将信息打印到控制台，这样你就可以看到程序的运行情况。

这是添加调试信息后的 `handle_connection` 函数：

```rust
fn handle_connection(mut stream: TcpStream) -> Result<(), String> {
    let mut buffer = [0; 512];
    stream.read(&mut buffer).unwrap();

    println!("Received: {:?}", String::from_utf8_lossy(&buffer));

    let mut protocol = Protocol::new();
    protocol.parse(&buffer)?;
    let response = protocol.handle_command()?;

    println!("Response: {:?}", response);

    stream.write(response.as_bytes()).unwrap();
    stream.flush().unwrap();

    Ok(())
}
```

在这个函数中，我们首先打印接收到的数据，然后解析数据并处理命令，然后打印响应的数据。这样，你就可以看到程序接收到的数据和响应的数据，这对于调试程序非常有用。

**pythias**: 执行过程发现只有Received没有Response，与是在`handle_command`里也添加了`println!("Handling command: {:?}", self.result);`，然后再次测试，等到的日志是 `Handling command: ["$4"]`，所以`parse_aggregate`里并没有安排REPS3的解析逻辑，你需要修改一下。

**GitHub Copilot**: 看起来你的 `parse_aggregate` 方法没有正确解析 RESP3 协议的数据。你需要确保它能正确解析出命令和参数。

这是一个可能的 `parse_aggregate` 方法的实现：

```rust
pub fn parse_aggregate(&mut self, data: &[u8]) -> Result<(), String> {
    let data = String::from_utf8_lossy(data);
    let mut lines = data.split("\r\n");

    let command_line = match lines.next() {
        Some(line) => line,
        None => return Err("No command line found".to_string()),
    };

    if !command_line.starts_with("*") {
        return Err("Invalid command line".to_string());
    }

    let count: usize = command_line[1..].parse().map_err(|_| "Invalid count".to_string())?;

    for _ in 0..count {
        let length_line = match lines.next() {
            Some(line) => line,
            None => return Err("No length line found".to_string()),
        };

        if !length_line.starts_with("$") {
            return Err("Invalid length line".to_string());
        }

        let length: usize = length_line[1..].parse().map_err(|_| "Invalid length".to_string())?;

        let data_line = match lines.next() {
            Some(line) => line,
            None => return Err("No data line found".to_string()),
        };

        if data_line.len() != length {
            return Err("Data line length mismatch".to_string());
        }

        self.result.push(data_line.to_string());
    }

    Ok(())
}
```

在这个实现中，我们首先解析命令行，然后解析每个参数的长度和数据。如果任何一步出错，我们都返回一个错误。如果所有的参数都成功解析，我们将它们添加到 `result` 中，然后返回 `Ok(())`。

**pythias**: 很好执行结果如下，但是用redis-cli测试时出现了错误，你可以帮我看一下吗？

```bash
    Finished dev [unoptimized + debuginfo] target(s) in 1.73s
     Running `target/debug/ai-redis`
Received: "*1\r\n$4\r\nPING\r\n"
Handling command: ["PING"]
Response: "PONG"
```

```bash
➜  ai-redis git:(master) ✗ echo -e "*1\r\n\$4\r\nPING\r\n" | nc localhost 7878
PONG%

➜  ai-redis git:(master) ✗ redis-cli -p 7878 PING
Error: Protocol error, got "P" as reply type byte
```

**GitHub Copilot**: `redis-cli` 工具期望的响应格式是 RESP（Redis Serialization Protocol）。在 RESP 中，一个简单字符串的回复是以 "+" 开头的。所以，当你的服务器回复 "PONG" 时，应该是 "+PONG"，而不仅仅是 "PONG"。

你需要修改 `handle_command` 方法，使其在回复 "PONG" 时，添加 "+" 前缀。这是修改后的 `handle_command` 方法：

```rust
pub fn handle_command(&self) -> Result<String, String> {
    match self.result.first() {
        Some(command) if command == "PING" => Ok("+PONG\r\n".to_string()),
        _ => Err("Unknown command".to_string()),
    }
}
```

在这个方法中，我们检查 `result` 的第一个元素是否是 "PING"。如果是，我们返回 "+PONG\r\n"。如果不是，我们返回一个错误。这样，你的服务器就能正确响应 `redis-cli` 的 PING 命令了。

> 执行 `cargo run` 启动服务器，然后在另一个终端执行 `redis-cli -p 7878 PING` 发送字符串到服务器。

```bash
➜  ai-redis git:(master) ✗ cargo run
   Compiling ai-redis v0.1.0 (/mnt/e/work/github/ai-redis)
    Finished dev [unoptimized + debuginfo] target(s) in 1.64s
     Running `target/debug/ai-redis`
Received: "*1\r\n$4\r\nPING\r\n"
Handling command: ["PING"]
Response: "+PONG\r\n"
Received: "*1\r\n$4\r\nPING\r\n\n"
Handling command: ["PING"]
Response: "+PONG\r\n"

```

## 其他章节

- [开始](/blog/2024/04/30/copilot-redis.html)
- 第一章
- [第二章](/blog/2024/05/08/copilot-redis-02.html)
