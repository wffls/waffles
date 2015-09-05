# Waffles

[TOC]

## About Waffles

Waffles is a configuration management system that helps you install, configure, and maintain services.

It is written in Bash 4.3 and uses core Linux utilities such as `grep`, `sed`, and `awk`. `rsync` is required to push deployments to remote systems.

Waffles also has a library of [Augeas](http://augeas.net)-based components. You can use Waffles without these components, but Augeas makes handling certain situations easier.

## Why Bash?

I chose Bash over another language such as Python, Ruby, Golang, etc because:

  * Bash is available on every Linux distribution out of the box. It's easy to install on FreeBSD and similar nix systems.
  * Configuring a nix-based system is all about running commands in a sequence as well as editing text files. This is exactly what Bash and the core utilities do.
  * Some configuration management systems just create Bash subprocesses to perform the underlying system changes anyway.

## Why "Waffles"?

I had all sorts of names for this project. "Composite" was the longest running name, but I always felt it was kind of boring. [Hecubus](https://www.youtube.com/watch?v=1L8wftRFLX0) was another front-runner. I eventually settled on "Waffles" because I wanted a name that was simple and wasn't too serious. And it's one of the first words I hear every morning when my son asks "wa-foos?".

## Contributing

All kinds of contributions are welcome:

* More docs
* More resources
* Better ways of accomplishing something
