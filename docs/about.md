# About Waffles

Waffles is my attempt to create a simple, lightweight configuration management system. It doesn't have all of the features that Puppet, Chef, Ansible, or others have, but it can still do a lot.

Waffles is very small and its core only uses Bash 4.3. rsync is required for push-based deployments.

I also chose to make heavy use of [Augeas](http://augeas.net/). Augeas, in my opinion, is a very underutilized tool. You can easily run Waffles without Augeas, but Augeas makes handling certain situations much easier.

_note_: Some parts of the standard library use tools such as `grep`, `sed`, `awk`, `coreutils`, etc. I consider these standard to any Linux distribution. If I ever get around to getting Waffles to work on FreeBSD, Windows, etc, changes may need made to the standard library. Also, using Waffles on very stripped down Linux containers may require modifications, too. Despite this caveat, I still consider Waffles to be a Bash-based configuration management system. Perhaps a more precise description is that Waffles is a Bash script to facilitate the configuration of Linux-based systems using a collection of other shell scripts and tools.

## Why Bash?

The main reasons why I chose Bash over another language such as Python, Ruby, Golang, etc are:

  * Bash is available on every Linux distribution out of the box. It's easy to install on FreeBSD and similar nix systems.
  * Configuring a nix-based system is all about running commands in a sequence as well as editing text files. This is exactly what Bash and the standard suite of unix utilities do. And they do this very well.
  * Some configuration management systems just create Bash subprocesses to perform the underlying system changes.

There are, of course, downsides to using Bash:

  * It's hard to parse YAML, JSON, etc in Bash.
  * Bash's data structures (arrays, hashes) can be weird.
  * It's hard to run on Windows.

I will be investigating these issues as time goes on and hopefully be able to find solutions. Until then, though, it is of my opinion that the outlined advantages outweigh the immediate disadvantages for use in Linux-based environments.

## Why "Waffles"?

I had all sorts of names for this project. "Composite" was the longest running name, but I always felt it was kind of boring. [Hecubus](https://www.youtube.com/watch?v=1L8wftRFLX0) was another front-runner. I eventually settled on "Waffles" because I wanted a name that was simple and wasn't too serious. And it's one of the first words I hear every morning when my son asks "wa-foos?".

# Future Plans

Waffles is still new. Although it can do quite a bit, there are some key features that I would like to see added:

* Shared Data: I'd like an easy way for nodes to be able to share information between each other, whether this feature is built into Waffles natively or uses an existing system like Consul.
* Pull-based Deployment: Push-based deployment requires direct access to the node. This isn't always possible in public cloud environments. A pull-based approach would only require the Waffles server to be accessible publicly.

## Contributing

All kinds of contributions are welcome:

* More docs
* More resources
* Better ways of accomplishing something

I'm by no means an expert programmer or Bash genius. I've learned a lot while making Waffles and still feel I have a long way to go. If you're also not a Bash expert, don't let that deter you from contributing -- we'll learn together. If you are an expert, feel free to fix poor style.
