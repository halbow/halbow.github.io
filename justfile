[private]
default:
    @just --list

run-dev:
    hugo server -D

build:
    hugo --minify

update-themes:
    git -C themes/PaperMod pull

new-post title:
    hugo new content posts/{{ title }}.md
