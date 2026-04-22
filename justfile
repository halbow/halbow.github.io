[private]
default:
    @just --list

run-dev:
    hugo server -D

build:
    hugo -b https://halbow.me -d docs
    git add docs

update-themes:
    git -C themes/PaperMod pull

new-post title:
    hugo new content posts/{{ title }}.md
