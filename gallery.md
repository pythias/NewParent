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

<h2>书法</h2>
<div class="gallery-image">
    {% assign calligraphy = site.calligraphy | sort: "date" | reverse %}
    {% for works in calligraphy %}
    {% assign thumbnail = site.baseurl | append: "/gallery/calligraphy/" | append: works.thumbnail %}
    <div class="img-box">
        <a href="{{ works.url }}" title="{{ works.title }}">
            <img src="{{ thumbnail }}" />
        </a>
    </div>
    {% endfor %}
</div>

<h2>摄影</h2>
<div class="gallery-image">
    {% assign photography = site.photography | sort: "date" | reverse %}
    {% for works in photography %}
    {% assign thumbnail = site.baseurl | append: "/gallery/photography/" | append: works.thumbnail %}
    <div class="img-box">
        <a href="{{ works.url }}" title="{{ works.title }}">
            <img src="{{ thumbnail }}" />
        </a>
    </div>
    {% endfor %}
</div>