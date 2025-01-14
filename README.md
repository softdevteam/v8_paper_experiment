# Experiment for V8 Handles Paper

The repository for the paper can be found at
https://github.com/softdevteam/v8_handles_paper.

## Running the experiments

To run the experiments on your local machine, you need to install dependencies
for your Linux distribution listed in the [Chromium build instructions](https://chromium.googlesource.com/chromium/src/+/main/docs/linux/build_instructions.md#notes-for-other-distros).

Then you can run `make build && make bench` to build and run the experiments.
You can set the `ITERS` environment variable to specify the number of times
each benchmark should be run. By default this is 10.

If you have access to Google's remoteexec build server, you can use set
`USE_REMOTE_EXEC=true` to ensure `make build` uses this.

After the experiments have run, the results will be available in
`chromium/src/third_party/crossbench/results`.

