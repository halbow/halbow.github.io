---
title: "Just do it ✅"
date: 2025-10-30T11:36:46+01:00
draft: true
---


If you've ever maintained a Makefile just to alias a few shell commands, [Just](https://github.com/casey/just) is probably what you actually want.

I've been using it for a while now and *just* wanted to share why I like it so much.

## What is Just ? 🕵️

Just is a command runner, which is simply a tool that helps you run commands. Usually it's a file where you define some commands
and how to run them:
```makefile
hello:
    echo "Hello, World"

run:
    docker-compose up -d
```

The most famous command runner is `make` but it comes with a lot of quirks due to the age
of the tool and the fact it was originally aimed at compiling C/C++. As soon as you want to pass some parameters, have some variables, etc,
it quickly becomes annoying.

[Just](https://github.com/casey/just) is a much more recent tool that focuses on being a *very good* command runner, taking
all the good things you could do with `make` without the historical complexity. It's much easier to define variables, pass arguments,
reuse other justfiles, etc.


## Why would you want to use command runners ?

They come with many advantages:

### Documentation on how to run your apps

In the end justfiles are just ... files, which means you can easily commit them to your VCS and they will serve both
as a command runner and as documentation on how you do things.

This can greatly improve the learning curve for new developers as they don't have to dig into the tool's details to
get started with the application, and they have a reference for all the useful commands to run against the app.

### Easier to keep up-to-date

By having the commands in a (kind of) executable format, it's easier to maintain than just listing
the commands in a README. As soon as you have an outdated or broken command, people will notice it
and can simply update the justfile and commit the changes.

If you only document the command in the README and there's a change to make, chances are developers
will encounter the issue before thinking about checking the README. And after finding the solution,
they have to remember that the command is listed in the README and update it.

### It serves as an interface for your application

Different applications may use different languages/frameworks but you often have to perform the same actions: run the app, build the container/package, update dependencies, migrate, etc.
A justfile can serve as a common abstraction on how to perform these routine tasks. This also eases the cognitive load of switching from one application to another.
No need to remember which package manager an application is using if you just have to run `just update-dependencies`.

Moreover, if you want to switch tools, let's say migrate from `poetry` to `uv`, you can do it while keeping
the same command and avoid interfering with the flow of other developers (besides maybe installing the tool in some cases).

## Some cool features of Just

Here's a few things I really like about Just

### Easy parameter handling

```makefile
generate-migrations title:
    run_migration -m {{ title }}

tests *args:
    pytest tests {{ args }}
```

This lets you customize commands on the fly and forward flags straight through, e.g. `just tests -k my_test`.

### Composable justfiles

You can run commands from other justfiles:
```makefile
migrate:
    just ../project_a/migrate
    just ../project_b/migrate
```

This is great for having a "main" justfile that orchestrates others. If you have services A, B and C, a top-level `just run` can call each service's own `just run`, giving you a one-command bootstrap for the whole stack while keeping each service's implementation details in its own repo/folder.

### Shebang integration

You can run arbitrary languages with a shebang:

```makefile
uuid:
  #!/usr/bin/env python3
  import uuid
  print(uuid.uuid4())
```

It's an easy way to do a bit more advanced scripting in whichever language you're most comfortable with. One use case is hooking Just into your app's CLI to build quick scripts that reuse your app's logic.

It also pairs nicely with the "main" justfile pattern: you can declare your services at the top of the justfile (and even group them, e.g. `backend` and `frontend`), then loop over them in bash to run the same command on each one.

### Command helpers

Things like confirmation prompts and grouping:

```makefile
[confirm('Are you sure you want to delete the database ?')]
[group('Migrations')]
scratch-db:
    run "DROP DB"
```

Nothing fancy here, you could do it yourself in a script, but Just gives you a nice interface for free. `[confirm(...)]` is a quick safety net on destructive commands, and once your justfile gets big, `[group(...)]` keeps `just --list` readable.

## What are the downsides ?

### Duplication between justfile and CI

One of the main downsides of using justfiles a lot is that you tend to have some duplication
between the commands in the justfile and the ones you use in your CI. For example, you will probably
have to update the command to run the tests both in the justfile and in the CI if you want to start checking the coverage.

### CLI oriented

Just is most appealing if you already spend a lot of time in your terminal. Some people prefer a different workflow, using the Docker Desktop app to start containers, configuring their IDE to run the tests, and so on. If they want to keep that workflow, they have to dig into the justfile and replicate the commands into their own tools. In that case Just still is a really nice source of truth: the way to run the app, the tests, the linter, etc. is documented and easy to execute.

## And that's it 

Just is 


## Justfile example

```Justfile
run_cmd := "docker compose -f docker-compose.yml"

app_name = "a_wonderful_app"

[private]
default:
    @just --list

[group('run')]
run:
    {{ run_cmd }} up -d {{ app_name }} --build    

[group('Package-Management')]
compile-dependencies:
    echo "whatever"

[group('Package-Management')]
upgrade-dependency dependency_name:
    echo "whatever"

[group('Package-Management')]
upgrade-all:
    echo "whatever"

[group('Migrations')]
migrate *arg:
    echo "whatever"

[group('Migrations')]
downgrade:
    echo "whatever"

[group('Migrations')]
scratch-db:
    echo "whatever"

[group('Migrations')]
seed-data *arg:
    echo "whatever"

[group('Tests')]
test *arg:
    echo "whatever"

```

Which gives a nice summary of all the commands available for your application:
```
Available recipes:
    [Migrations]
    downgrade
    migrate *arg
    scratch-db
    seed-data *arg

    [Package-Management]
    compile-dependencies
    upgrade-all
    upgrade-dependency dependency_name

    [Tests]
    test *arg

    [run]
    run
```
