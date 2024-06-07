---
layout: post
title: "帮我发到微博"
description: "ChatGPT帮我扩展将内容发到微博"
date: 2024-06-07

tags: ["AI", "Copilot", "Chrome", "Extension", "Weibo"]
categories: blog

---

今天是高考的日子，我已经错过了十几年。我需要写作文，自然想到使用AI来帮助我，于是我使用了ChatGPT来写了一篇。但是，一篇一篇地将文章搬运到微博上实在太麻烦了，我开始思考是否可以有一个插件帮我直接发布到微博上，因此我编写了这个插件。

上一个话题已经停了很久了，我决定先用ChatGPT帮我编写一个插件。

pythias: 我想写一个工具把AI对话中的内容发到微博中，第一个版本就简单的基于Chrome浏览器的扩展来实现，比如ChatGPT的页面中有“阅读”,"复制","点赞","选择模型"等按钮，扩展加上一个"发微博"的按钮，点击的时候跳转到微博的发布页，把内容复制过去，如果有图片也一同复制。

> 插曲，被AI鄙视了... ChatGPT: 这个功能是不是有点多余？你可以直接复制内容到微博中，为什么还要做一个插件？

这个项目听起来很有意思。以下是一个简要的实现步骤，帮助你创建一个Chrome扩展，能够从ChatGPT页面中将对话内容发布到微博：

### 步骤 1: 创建Chrome扩展基本结构

#### 1.1 创建项目文件夹

创建一个文件夹来存放你的扩展文件，比如 `chatgpt-weibo-extension`。

#### 1.2 创建 `manifest.json`

在项目文件夹中创建一个 `manifest.json` 文件，这是Chrome扩展的配置文件。

```json
{
  "manifest_version": 3,
  "name": "ChatGPT Weibo Poster",
  "version": "1.0",
  "description": "Post ChatGPT conversations to Weibo",
  "permissions": [
    "activeTab",
    "storage",
    "clipboardWrite",
    "clipboardRead"
  ],
  "action": {
    "default_popup": "popup.html"
  },
  "content_scripts": [
    {
      "matches": ["https://chat.openai.com/*"],
      "js": ["content.js"]
    }
  ]
}
```

### 步骤 2: 创建内容脚本

#### 2.1 创建 `content.js`

在项目文件夹中创建 `content.js` 文件，这个脚本会在ChatGPT页面加载时运行，并在页面上添加“发微博”按钮。

```javascript
document.addEventListener('DOMContentLoaded', function () {
  // 查找或创建一个按钮容器
  const container = document.querySelector('header') || document.body;

  // 创建一个新的按钮
  const weiboButton = document.createElement('button');
  weiboButton.innerText = "发微博";
  weiboButton.style.margin = "10px";
  weiboButton.style.padding = "10px";
  weiboButton.style.backgroundColor = "#E6162D"; // 微博的红色
  weiboButton.style.color = "white";
  weiboButton.style.border = "none";
  weiboButton.style.borderRadius = "5px";
  weiboButton.style.cursor = "pointer";

  // 按钮点击事件
  weiboButton.onclick = function () {
    // 获取对话内容
    const chatContent = document.querySelector('.conversation');
    if (chatContent) {
      const text = chatContent.innerText;
      chrome.storage.local.set({ chatContent: text }, function () {
        window.open('https://weibo.com/');
      });
    } else {
      alert("未找到对话内容！");
    }
  };

  // 将按钮添加到页面
  container.appendChild(weiboButton);
});
```

### 步骤 3: 创建弹出页面

#### 3.1 创建 `popup.html`

在项目文件夹中创建 `popup.html` 文件，这个页面将在点击扩展图标时弹出。

```html
<!DOCTYPE html>
<html>
<head>
  <title>ChatGPT Weibo Poster</title>
  <script src="popup.js"></script>
</head>
<body>
  <h1>Post to Weibo</h1>
  <button id="postToWeibo">Post</button>
</body>
</html>
```

#### 3.2 创建 `popup.js`

在项目文件夹中创建 `popup.js` 文件，这个脚本会处理从存储中获取对话内容并将其粘贴到微博的发布页面。

```javascript
document.getElementById('postToWeibo').addEventListener('click', function () {
  chrome.storage.local.get(['chatContent'], function (result) {
    const chatContent = result.chatContent;
    if (chatContent) {
      const weiboUrl = `https://weibo.com/compose?content=${encodeURIComponent(chatContent)}`;
      chrome.tabs.create({ url: weiboUrl });
    } else {
      alert("没有对话内容！");
    }
  });
});
```

### 步骤 4: 测试和调试

1. 打开Chrome浏览器，进入扩展管理页面 `chrome://extensions/`。
2. 打开“开发者模式”。
3. 点击“加载已解压的扩展程序”，选择你的项目文件夹。
4. 访问ChatGPT页面，查看是否有“发微博”按钮，并测试其功能。

这样，你就有了一个简单的Chrome扩展，可以从ChatGPT页面将对话内容发布到微博。你可以根据需要进一步完善和优化这个扩展。
