#!/usr/bin/env bash

push() {
    image=$1
    category=$2
    base_name=$(basename -- "$image")
    extension="${base_name##*.}"
    file_name="${base_name%.*}"
    year=`stat -x $image | grep "Modify:" | awk '{print $6"-"$3}'`
    datetime=`stat -x $image | grep "Modify:" | awk '{print substr($0, 9)}'`
    original="${ROOT}/gallery/${category}/${year}/${file_name}-original.${extension}"
    thumbnail="${ROOT}/gallery/${category}/${year}/${file_name}-thumbnail.${extension}"

    [ ! -d "${ROOT}/gallery/${category}/${year}" ] && mkdir -p "${ROOT}/gallery/${category}/${year}"

    height=`sips -g pixelHeight $image | tail -1 | awk '{print $2}'`
    width=`sips -g pixelWidth $image | tail -1 | awk '{print $2}'`
    if [[ $width > $height ]]; then
        sips --resampleHeight 480 -c 480 480 $image -o $thumbnail > /dev/null
    else
        sips --resampleWidth 480 -c 480 480 $image -o $thumbnail > /dev/null
    fi

    cp $image $original

    md="${ROOT}/_works/${file_name}.md"
    echo "---" > $md
    echo "layout: post-livere" >> $md
    echo "category: ${category}" >> $md
    echo "name: ${file_name}" >> $md
    echo "original: ${year}/${file_name}-original.${extension}" >> $md
    echo "thumbnail: ${year}/${file_name}-thumbnail.${extension}" >> $md
    echo "date: ${datetime}" >> $md
    echo "title: 标题" >> $md
    echo "---" >> $md
    echo "" >> $md
    echo "![{{page.title}}](/gallery/{{page.category}}/{{page.original}})" >> $md
    echo "故事内容" >> $md
}

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && cd .. && pwd )"
IMAGE=$1
TARGET=$2
if [[ -z $TARGET ]]; then
    TARGET="paintings"
fi

if [[ -d $IMAGE ]]; then
    for f in $IMAGE/*; do
        push $f $TARGET
    done
elif [[ -f $IMAGE ]]; then
    push $IMAGE $TARGET
else
    echo "$IMAGE is not valid"
    exit 1
fi