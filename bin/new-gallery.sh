#!/usr/bin/env bash

push() {
    image=$1
    target=$2
    base_name=$(basename -- "$image")
    extension="${base_name##*.}"
    file_name="${base_name%.*}"
    original="${target}/${file_name}-original.${extension}"
    thumbnail="${target}/${file_name}-thumbnail.${extension}"
    datetime=`stat -x $image | grep "Modify:" | awk '{print substr($0, 9)}'`

    height=`sips -g pixelHeight $image | tail -1 | awk '{print $2}'`
    width=`sips -g pixelWidth $image | tail -1 | awk '{print $2}'`
    if [[ $width > $height ]]; then
        sips --resampleHeight 480 -c 480 480 $image -o $thumbnail > /dev/null
    else
        sips --resampleWidth 480 -c 480 480 $image -o $thumbnail > /dev/null
    fi

    cp $image $original

    echo ""
    echo "- filename: ${file_name}"
    echo "  original: ${file_name}-original.${extension}"
    echo "  thumbnail: ${file_name}-thumbnail.${extension}"
    echo "  painted_at: ${datetime}"
    echo "  title: 标题"
    echo "  caption: 说明"
    echo "  story: 故事内容"
    echo ""
}

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && cd .. && pwd )"
IMAGE=$1
TARGET=$2
if [[ -z $TARGET ]]; then
    TARGET="duo/paintings"
fi

if [[ -d $IMAGE ]]; then
    for f in $IMAGE/*; do
        push $f $ROOT/gallery/$TARGET
    done
    
elif [[ -f $IMAGE ]]; then
    push $IMAGE $ROOT/gallery/$TARGET
else
    echo "$IMAGE is not valid"
    exit 1
fi
