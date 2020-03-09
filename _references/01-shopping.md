---
layout: post
title: 购物网站
sites:
    - name: 亚马逊
      url: https://www.amazon.com/
      nation: 美国
      staff: 各种
      mail: 部分直邮
      pay: 信用卡或者Paypal
    - name: iHerb
      url: https://www.iherb.cn/
      nation: 美国
      staff: 吃的，营养品偏多
      mail: 部分直邮
      pay: 支付宝 
    - name: kidsroom
      url: https://www.kidsroom.de/
      nation: 德国
      staff: 安全座椅等
      mail: 可以直邮
      pay: 支付宝，银联等
    - name: 顺风海淘
      url: https://www.fengqu.com/
      nation: 各地
      staff: 各种
      mail: 可以直邮
      pay: 支付宝，微信 
---

<ul class="post-list">
{% for site in page.sites %}
<li>
    <span class="post-meta">{{ site.staff | escape }}，{{ site.mail | escape}} from {{ site.nation | escape}}</span>
    <h3><a class="post-link" href="{{ site.url }}">{{ site.name | escape }}</a></h3>
</li>
{% endfor %}
</ul>
