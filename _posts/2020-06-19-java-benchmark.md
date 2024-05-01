---
layout: post-livere
title: "关于Java的性能测试"
description: "在斤斤计较的过程中提升"
date: 2020-06-19

tags: ["Java", "benchmark", "jmh"]
categories: blog

---

今天读到一篇InfoQ上的[文章](https://xie.infoq.cn/article/cae1455171caa912d103a5b8e)，针对阿里「Java开发手册」中日志输出规范中关于字符串拼接和占位符的性能提出质疑，规范如下：

    【强制】在日志输出时，字符串变量之间的拼接使用占位符的方式。
    说明：因为 String 字符串的拼接会使用 StringBuilder 的 append()方式，有一定的性能损耗。使用占位符仅是替换动作，可以有效提升性能。
    正例：logger.debug("Processing trade with id: {} and symbol: {}", id, symbol);

突然也想写点关于性能测试的文章来开启blog

## 关于性能测试

作为经济适用程序员，斤斤计较是其中一个特性「以后说其他更多特性」，能一纳秒完成就不给两纳秒，如何使用更少的时间实现相同功能是需要经常锻炼的砍价能力。

如何评价效率/性能，从接口至逻辑都有相应的工具进行测试。接口的性能测试这儿不介绍了，如何针对我们写的逻辑也就是一段代码或者一个方法进行测试呢，写N多年前写PHP的时候最常见写法是

```php
$count = 1000000;
$begin = microtime(true);
for ($i = 0; $i < $count; $i++) {
    # code...
}
$total_seconds = microtime(true) - $begin;
$qps = round($count / $total_seconds, 2);
```

但到了Java发现这么写，得到的结果前面的几次性能明显差于后来的，比如

```java
public class Sample001 {
    public static void main(String[] args) {
        for (int round = 0; round < 10; round++) {
            long begin = System.nanoTime();
            int count = 100_000;
            for (int i = 0; i < count; i++) {
                cat();
            }
            System.out.printf("Round %03d, finished %d in %2.3f ms\n", round, count, (System.nanoTime() - begin) / 1_000_000.0);
        }
    }

    private static long cat() {
        String a = "";
        for (int i = 0; i < 10; i++) {
            a += i;
        }
        return a.length();
    }
}
```

执行10轮的结果如下：

```bash
# javac Sample001.java && java -Xms1G -Xmx1G Sample001
Round 000, finished 100000 in 40.474 ms
Round 001, finished 100000 in 37.225 ms
Round 002, finished 100000 in 36.471 ms
Round 003, finished 100000 in 35.715 ms
Round 004, finished 100000 in 34.391 ms
Round 005, finished 100000 in 13.165 ms
Round 006, finished 100000 in 14.205 ms
Round 007, finished 100000 in 14.137 ms
Round 008, finished 100000 in 17.646 ms
Round 009, finished 100000 in 18.273 ms
```

大概五次以后性能从约40ms提升至15ms，把代码改一下`int count = 500_000;`验证一下，确实了当`cat()`执行了五十万次左右的时候性能上了一个台阶：

```bash
# javac Sample001.java && java -Xms1G -Xmx1G Sample001
Round 000, finished 500000 in 178.598 ms
Round 001, finished 500000 in 68.093 ms
Round 002, finished 500000 in 58.356 ms
Round 003, finished 500000 in 58.449 ms
Round 004, finished 500000 in 75.782 ms
Round 005, finished 500000 in 60.858 ms
Round 006, finished 500000 in 79.830 ms
Round 007, finished 500000 in 77.924 ms
Round 008, finished 500000 in 63.239 ms
Round 009, finished 500000 in 63.782 ms
```

为何呢？这就是[JIT](https://www.ibm.com/developerworks/cn/java/j-lo-just-in-time/index.html)的功劳了。

然后[JMH (Java Microbenchmark Harness)](https://openjdk.java.net/projects/code-tools/jmh/)就登场了，JMH有一个预热（Warmup）的过程，预热让逻辑中可优化进入优化状态，让测试结果更接近真实（当然也许真实使用时并没有达到JIT的阈值，回头分析一下JIT的具体实现和触发）。

## JMH的使用

使用maven创建一个JMH的工程

```sh
mvn archetype:generate \
  -DinteractiveMode=false \
  -DarchetypeGroupId=org.openjdk.jmh \
  -DarchetypeArtifactId=jmh-java-benchmark-archetype \
  -DgroupId=org.sample \
  -DartifactId=sample002 \
  -Dversion=1.0
```

添加测试用例，加上标注 @Benchmark

```java
package org.sample;

import org.openjdk.jmh.annotations.Benchmark;

public class MyBenchmark {
    @Benchmark
    public long testCat() {
        String a = "";
        for (int i = 0; i < 10; i++) {
            a += i;
        }
        return a.length();
    }

    @Benchmark
    public long testBuilder() {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 10; i++) {
            sb.append(i);
        }
        return sb.toString().length();
    }
}
```

编译后执行，结果如下：

```sh
mvn clean package
java -jar target/benchmarks.jar
# JMH version: 1.21
# VM version: JDK 1.8.0_202, Java HotSpot(TM) 64-Bit Server VM, 25.202-b08
# VM invoker: /Library/Java/JavaVirtualMachines/jdk1.8.0_202.jdk/Contents/Home/jre/bin/java
# VM options: <none>
# Warmup: 5 iterations, 10 s each
# Measurement: 5 iterations, 10 s each
# Timeout: 10 min per iteration
# Threads: 1 thread, will synchronize iterations
# Benchmark mode: Throughput, ops/time
# Benchmark: org.sample.MyBenchmark.testBuilder

# Run progress: 0.00% complete, ETA 00:16:40
# Fork: 1 of 5
# Warmup Iteration   1: 29079775.131 ops/s
# Warmup Iteration   2: 12154565.069 ops/s
# Warmup Iteration   3: 12958559.652 ops/s
# Warmup Iteration   4: 12721430.371 ops/s
# Warmup Iteration   5: 13166449.495 ops/s
Iteration   1: 13021760.958 ops/s
Iteration   2: 13536462.453 ops/s
Iteration   3: 13469708.323 ops/s
Iteration   4: 13416607.185 ops/s
Iteration   5: 12752605.574 ops/s

...

Benchmark                 Mode  Cnt         Score        Error  Units
MyBenchmark.testBuilder  thrpt   25  13265478.693 ± 697017.778  ops/s
MyBenchmark.testCat      thrpt   25   2469800.468 ± 138938.866  ops/s
```

例子中跑了两个测试一个是 MyBenchmark.testCat 和 MyBenchmark.testBuilder

- `# Fork: 1 of 5`: 每个5次测试（)
- `# Warmup: 5 iterations, 10 s each`: 每次测试包含5次10秒的预热
- `# Measurement: 5 iterations, 10 s each`: 每次测试包含5轮10秒的测试
- `# Threads: 1 thread, will synchronize iterations`: 每次测试开1个线程
- `# Run complete. Total time: 00:16:45`: 一共花了约16分钟

通过参数或者标注可以对这几个数值进行修改。

### 通过参数调整

```java
public static void main(String[] args) throws RunnerException {
    Options options = new OptionsBuilder()
            .include(MyBenchmark.class.getSimpleName())
            .forks(2)
            .threads(2)
            .warmupIterations(2)
            .warmupTime(TimeValue.seconds(2))
            .measurementBatchSize(2)
            .measurementTime(TimeValue.seconds(2))
            .build();
    new Runner(options).run();
}
```

执行结果如下：

```sh
➜  sample002 git:(code) ✗ java -cp target/benchmarks.jar org.sample.MyBenchmark
# JMH version: 1.21
# VM version: JDK 1.8.0_202, Java HotSpot(TM) 64-Bit Server VM, 25.202-b08
# VM invoker: /Library/Java/JavaVirtualMachines/jdk1.8.0_202.jdk/Contents/Home/jre/bin/java
# VM options: <none>
# Warmup: 2 iterations, 2 s each
# Measurement: 2 iterations, 2 s each
# Timeout: 10 min per iteration
# Threads: 2 threads, will synchronize iterations
# Benchmark mode: Throughput, ops/time
# Benchmark: org.sample.MyBenchmark.testBuilder
```

### 通过标注调整

```java
@BenchmarkMode(Mode.Throughput)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Threads(3)
@Fork(3)
public class MyBenchmark {

}
```

执行结果如下：

```sh
➜  sample002 git:(code) ✗ java -jar target/benchmarks.jar
# JMH version: 1.21
# VM version: JDK 1.8.0_202, Java HotSpot(TM) 64-Bit Server VM, 25.202-b08
# VM invoker: /Library/Java/JavaVirtualMachines/jdk1.8.0_202.jdk/Contents/Home/jre/bin/java
# VM options: <none>
# Warmup: 3 iterations, 5 s each
# Measurement: 3 iterations, 5 s each
# Timeout: 10 min per iteration
# Threads: 3 threads, will synchronize iterations
# Benchmark mode: Throughput, ops/time
# Benchmark: org.sample.MyBenchmark.testBuilder
```

另外在输出中还发现 `# VM options: <none>`，VM参数也可以通过以上两种方式进行调整，Fork标注中可以添加参数，如`@Fork(value = 3, jvmArgs = {"-Xms1G", "-Xmx1G"})`等。

## 日志输出

前面两个章节说了Java如何做性能测试，从古老的循环执行统计时间到使用JMH工具进行预热和执行。回到文章开头说的两个日志的使用方法字符串拼接与占位符性能问题，文章也解析了slf4j的源码，细节不再阐述。

六个用例，分别是

- testDebug: 普通DEBUG
- testDebugWithIf: 添加判断的DEBUG
- testDebug5: 五个参数占位符的DEBUG
- testDebugWithIf5: 添加判断、五个参数占位符的DEBUG
- testInfo5: 五个参数占位符的INFO
- testInfoBuild5: 五个参数拼接的INFO

[代码](https://github.com/pythias/jie.sh/tree/code/code/sample003)如下：

```java
@Benchmark
public void testDebug() {
    log.debug("Hello.");
}

@Benchmark
public void testDebugWithIf() {
    if (log.isDebugEnabled()) {
        log.debug("Hello.");
    }
}

@Benchmark
public void testDebug5() {
    log.debug("Hello {}, {}, {}, {}, {}.", "one", "two", "three", "four", "five");
}

@Benchmark
public void testDebugWithIf5() {
    if (log.isDebugEnabled()) {
        log.debug("Hello {}, {}, {}, {}, {}.", "one", "two", "three", "four", "five");
    }
}

@Benchmark
public void testInfo5() {
    log.info("Hello {}, {}, {}, {}, {}.", "one", "two", "three", "four", "five");
}

@Benchmark
public void testInfoBuild5() {
    StringBuilder sb = new StringBuilder("Hello ");
    sb.append("one").append(", ").append("two").append(", ");
    sb.append("three").append(", ").append("four").append(", ");
    sb.append("five").append(".");
    log.info(sb.toString());
}
```

执行结果如下：

```bash
# Run complete. Total time: 00:10:43
Benchmark                      Mode  Cnt           Score           Error  Units
MyBenchmark.testDebug         thrpt    9  1130576386.310 ± 111537882.560  ops/s
MyBenchmark.testDebug5        thrpt    9  1191771199.022 ±  82513902.896  ops/s
MyBenchmark.testDebugWithIf   thrpt    9  1352370214.289 ±  20520868.587  ops/s
MyBenchmark.testDebugWithIf5  thrpt    9  1354268920.782 ±  68562339.128  ops/s
MyBenchmark.testInfo5         thrpt    9      137841.892 ±     13788.722  ops/s
MyBenchmark.testInfoBuild5    thrpt    9      148135.404 ±     13144.961  ops/s
```

### 场景1：开发的DEBUG日志怎么打

添加`isDebugEnabled()`的判断是否有必要

```java
if (log.isDebugEnabled()) {
    log.debug("Hello.");
}
```

对比用例 `testDebug5` VS `testDebugWithIf5` 或者 `testDebug` VS `testDebugWithIf`，当日志不需要输出时过程极快不到1纳米一次，多了判断的过程也就是让执行时间从0.839纳秒/次提升至0.739纳秒/次，虽然11.9%那么多的提升，但0.01纳米对于业务逻辑的毫秒处理过程来说可以忽略不计。

但有些日志记录中参数是其他方法，这种情况就另说了，比如：

```java
if (log.isDebugEnabled()) {
    log.debug("Hello, {}", obj->getSomeValue());
}
```

一般 `obj->getSomeValue()` 也只是获取对象的属性，如果 `obj->getSomeValue()` 是一个复杂的过程，这么设计也太不讲究太不规范了。

### 场景2：一个参数和五个参数的区别

对比方法执行时，传输参数数量对于性能的差异，想通过`testDebug` VS `testDebug5`来对比，但是这个测试用例不严禁，干扰太多，得空再进行针对性的分析。

### 场景3：拼接还是占位符

源码里占位符的实现也是采用了拼接的方式，只是在代码编写是更加优雅，用例 `testInfo5` VS `testInfoBuild5` （差异因本机IO影响较大忽略前后）两者性能基本在6.75微秒/次，基本所有时间都消耗在要么有磁盘IO要么有网络IO的操作（当然我们可以定期再flush各种方式进行优化），所以拼接还是占位符那点性能差异也可以忽略。

### 场景4：写日志和不写日志

`testDebug5` VS `testInfo5`

## 结论

1. 用占位符，写起来好看；
2. 无需判断debugEnabled，直接使用log->debug()，性能差异可忽略；
3. 一个方法里参数里执行复杂过程是错误写法。

---

*测试环境（测试结果不是很严谨，因为测试时还在作别的，特别是写日志时磁盘IO影响较大，但相对数据及整体结论还是没有太多影响）：*

```bash
iMac (Retina 4K, 21.5-inch, Late 2015)
3.1 GHz Quad-Core Intel Core i5
8 GB 1867 MHz DDR3
```

参考:

1. [JIT](https://www.ibm.com/developerworks/cn/java/j-lo-just-in-time/index.html)
2. [JMH (Java Microbenchmark Harness)](https://openjdk.java.net/projects/code-tools/jmh/)
3. [驳《阿里「Java 开发手册」中的 1 个 bug》？](https://xie.infoq.cn/article/cae1455171caa912d103a5b8e)
