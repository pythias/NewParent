---
layout: page
title: 作品
---

<link rel="stylesheet" href="{{ site.baseurl }}/assets/css/gallery.css" />

<h2>绘画</h2>
<div class="gallery-image">
    {% assign paintings = site.paintings | sort: "date" | reverse %}
    {% for painting in paintings %}
    {% assign thumbnail = site.baseurl | append: "/gallery/paintings/" | append: painting.thumbnail %}
    <div class="img-box">
        <a href="{{ painting.url }}" title="{{ painting.title }}">
            <img src="{{ thumbnail }}" />
        </a>
    </div>
    {% endfor %}
</div>