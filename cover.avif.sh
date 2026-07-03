#!/bin/sh

# TODO set config values
cover_src=077-compress-jpeg/229.jpg

magick "$cover_src" -scale 50% -quality 50% cover.avif
