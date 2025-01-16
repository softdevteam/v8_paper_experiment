# Experiment for V8 Handles Paper

This is the experiment for the [V8 handles
paper](https://github.com/sfotdevteam/v8_handles_paper). It uses the
[BrowserBench](https://browserbench.org/) benchmarking suite (JetStream3,
MotionMark1.2, Speedometer2.1) to compare four different Chrome configurations: 

* ***Handles***: pointers to heap objects on the stack use indirection to
  inform the collector of roots. The GC does not use conservative stack
  scanning. (currently in use in production)
* ***Direct Refs***: uses "regular" pointers to heap objects on the stack. The
  GC uses conservative scanning to identify pointers on the stack (enabled by
  the `v8_enable_conservative_stack_scanning=true` GN arg).
* ***Handles (no compression)***: ***Handles***, but with pointer compression
  disabled (`v8_enable_pointer_compression=false`).
* ***Direct Refs (no compression)***: ***Direct Refs***, but with pointer
  compression disabled (`v8_enable_pointer_compression=false`).

All configurations are built using the same GN arguments:

```
dcheck_always_on=false
is_debug=false
enable_nacl=false
is_component_build=false
```

For more information, the accompanying design document can be found
[here](https://docs.google.com/document/d/1bOPW-Bb_aAefrgXGI8yhwEPxULePkLcNY8RaOvnbJKU/edit?tab=t.0#heading=h.wb0el8iqan2r).

## Running the experiments

To run the experiments on your local machine, you need to install dependencies
for your Linux distribution listed in the [Chromium build
instructions](https://chromium.googlesource.com/chromium/src/+/main/docs/linux/build_instructions.md#notes-for-other-distros).

> [!NOTE]
> If you intend to benchmark on a machine without an X/Wayland display server,
> you can set the `USE_XVFB=true` environment variable to ensure that Chrome is
> run inside a virtual display. You will need to have `xvfb` installed to use this.

Then you can run `make` to build and run the experiments.
You can set the `ITERS` environment variable to specify the number of times
each benchmark should be run. By default this is 10.

> [!IMPORTANT]
> For more reliable results, ensure that CPU frequency scaling is set to
> `performance`. There is a convenience script for this in the V8 repo which is
> available after `make build` has finished downloading Chromium. It can be
> enabled as follows:
>
> `sudo ./chromium/src/v8/tools/cpu.sh performance`

If you have access to Google's remoteexec build server, you can use set
`USE_REMOTE_EXEC=true` to ensure `make build` uses this.

After the experiments have run, the results will be available in
`chromium/src/third_party/crossbench/results`.

## Results output

Currently, this script outputs the results of each benchmark to a file
containing a table formatted using Markdown. We'll want to change this at some
point, but for now it can be easily modified by editing `process.py` to output
the results in a format of your choosing.
