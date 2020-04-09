---
layout: page
title: 作品
---

<link rel="stylesheet" href="{{ site.baseurl }}/assets/css/gallery.css" />

<h2>绘画</h2>
<div class="gallery-image">
    {% assign paintings = site.paintings | sort: "date" | reverse %}
    {% for painting in paintings %}
    {% assign thumbnail = site.baseurl | append: "/gallery/" | append: painting.type | append: "/" | append: painting.thumbnail %}
    <div class="img-box">
        <a href="{{ painting.url }}" title="西游记">
            <img src="{{ thumbnail }}" alt="{{ painting.title }}"/>
            <div class="transparent-box">
                <div class="caption">
                    <p>{{ painting.title }}</p>
                </div>
            </div>
        </a>
    </div>
    {% endfor %}
</div>