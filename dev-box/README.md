# Remote Builder Stack

This is a helper to spawn up a beefy machine on AWS and use it to build stuff
with nix's distributed build.

## Building PI4 kernel: (after the machine is up)
pulumi stack output nixBuildPi4KVM | bash

