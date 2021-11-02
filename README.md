nishell
=======

This is a set of commands that I find myself running frequently.
In order to avoid repetition and reduce carpal tunnel risks, I collected them together.
Maybe you'll find them useful, maybe not. The quick and dirty batch-able wrap around `fsleyes` (`slice_coeffs`) is quite neat though.

Usage
-----
Clone this repo and source `nishell.sh` in your `.bashrc`, `.bash_profile`, or whatever file you prefer to source things.

Warning
-------
Nothing here is tested (beside daily use), and I doubt I'll test it.
Also, it's in forever-alpha stage (unless somebody writes tests, then it might become a forever-beta).

If you find this useful, I don't know, ask me how to cite this library? Or just don't.

Also, if you want to help with documentation (like help messages), please do. Or with anything else, really.

Real warning
------------
In order for `slice_coeffs` to work, you need to have `fsleyes` installed. I think the minimal version required is `1.0.5`.
For full disclosure, I installed it via `pip` because I'm chaotic-aligned like that.

If you have problem running it, you might need to change the command call to `FSLeyes`, or source the right path to `fsleyes`.
You can check if everything is ok with `which fsleyes`, and `fsleyes --version`

Also have a look at the additional cmaps added here. If you want to install them (Viridis is quite a nice colourmap!) you can follow the instructions in the `fsleyes` wiki. I just added the `.cmap` files in the `~/.config/fsleyes/colourmaps` and it worked for me, but maybe it's going to be different for you.


_Cheers!_
