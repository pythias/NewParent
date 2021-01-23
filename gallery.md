---
layout: page
title: 作品
permalink: /gallery
pagination: 
  enabled: true
  collection: works
  per_page: 8
  permalink: /:num.html
  sort_field: 'date'
  sort_reverse: true
---

<link rel="stylesheet" href="{{ site.baseurl }}/assets/css/bootstrap-grid.min.css" />
<link rel="stylesheet" href="{{ site.baseurl }}/assets/css/bootstrap-card.css" />
<link rel="stylesheet" href="{{ site.baseurl }}/assets/css/bootstrap-images.css" />
<link rel="stylesheet" href="{{ site.baseurl }}/assets/css/pagination.css" />

{% assign works = paginator.posts %}

<div class="row">
    {% for paintings in works %}
    {% assign thumbnail = site.baseurl | append: "/gallery/" | append: paintings.category | append: "/" | append: paintings.thumbnail %}
    <a class="col-lg-3 col-md-4 col-6 my-3" href="{{ paintings.url }}" title="{{ paintings.title }}" >
        <img class="img-fluid card" src="{{ thumbnail }}" />
    </a>
    {% endfor %}
</div>

<div class="row">
  {%- if paginator.previous_page %}
    <a class="col-6 pagination-previous" href="{{ paginator.previous_page_path | relative_url }}" class="previous-page">&larr;上一页</a>
  {%- else %}
    <div class="col-6 pagination-previous">&larr;上一页</div>
  {%- endif %}
  {%- if paginator.next_page %}
    <a class="col-6 pagination-next" href="{{ paginator.next_page_path | relative_url }}" class="next-page">下一页&rarr;</a>
  {%- else %}
    <div class="col-6 pagination-next">下一页&rarr;</div>
  {%- endif %}
</div>