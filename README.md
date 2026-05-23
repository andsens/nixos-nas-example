# nixos-nas-example

An example configuration for a NAS running [nixos-homelab](https://github.com/andsens/nixos-homelab).

It's about 1000 lines of Nix, with concrete user setup, service configs, backup,
VM testing, the works.  
The structure is still somewhat a mess, but manageable. I will update the repo
once I think of a better way to organize everything.

## Usage

You don't. This is an example repo. If you were to replace all bogus parameters
it would work. But without understanding what most of the other parameters
you didn't change do you'll have a bad time.  
The point of this repo is not to document options and module behavior, it's
meant as a quick entry-point to set things up yourself. Concrete examples
are usually much quick to understand than multiple paragraphs of text.

That being said, you _can_ run the prebuilt VM with `nix run '.#nas'` if you
want to explore the setup.

`nix run '.#installer'` also works, if you want to see what an unattended
install looks like.

## Useful commands

- `nix run '.#deploy'`: Run `nixos-rebuild`with`--target-host` and deploy the configuration to your NAS
- `nix run '.#diff'`: Compare the current configuration with whatever is linked in `result/`
  (run `nix build '.#nixosConfigurations.nas.config.system.build.toplevel'` to build the current configuration and link to it from`result`)
- `nix run '.#update'`: Useful for module development. Updates all modules to the code in your module working copies.
- `nix run '.#nas'`: Run the current configuration in a VM.
- `nix run '.#installer'`: Launch a VM that boots into an unattended install of the current configuration.
