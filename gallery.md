---
layout: page
title: 作品
---

<link rel="stylesheet" href="{{ site.baseurl }}/assets/css/bootstrap-grid.min.css" />
<link rel="stylesheet" href="{{ site.baseurl }}/assets/css/bootstrap-card.css" />
<link rel="stylesheet" href="{{ site.baseurl }}/assets/css/bootstrap-images.css" />

<div class="row">
    {% assign works = site.works | sort: "date" | reverse %}
    {% for painting in works %}
    {% assign thumbnail = site.baseurl | append: "/gallery/" | append: painting.category | append: "/" | append: painting.thumbnail %}
    <a class="col-lg-3 col-md-4 col-6 my-3" href="{{ painting.url }}" title="{{ painting.title }}" >
        <img class="img-fluid card" src="{{ thumbnail }}" />
    </a>
    {% endfor %}
</div>
