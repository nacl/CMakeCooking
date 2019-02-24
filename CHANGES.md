v0.10.1
------
2019-02-07

- Restore the old behavior for recipe file resolution: `-r foo` will resolve to `${source_dir}/recipe/foo.cmake`, and if `-r` is not provided then by default the recipe is expected to be `cooking_recipe.cmake`. ([GH-16](https://github.com/hakuch/CMakeCooking/issues/16))

v0.10.0
------
2019-01-29

- Write `Cooking.cmake` to the build directory instead of the source directory ([GH-14](https://github.com/hakuch/CMakeCooking/issues/14))
- Assume a default recipe file called `cooking_recipe.cmake` and change the way custom recipes are resolved to files ([GH-13](https://github.com/hakuch/CMakeCooking/issues/13))

v0.9.0
------
2018-12-31

- Require dune version 1.6 for OCaml tests
- Fix an error when `cooking.sh` is invoked without a recipe ([GH-1](https://github.com/hakuch/CMakeCooking/issues/1))
- Allow installed ingredients to be exported to the file-system ([GH-2](https://github.com/hakuch/CMakeCooking/issues/2))

v0.8.1
------
2018-10-08

- Also forward the CMake generator when listing ingredients
- Change the way local synchronization works (remove `cmake_mark_targets` for being too intrusive). See `APPLY.md` for details
- Ensure that ingredients with their own recipes re-stow their files every time `cooking.sh` is executed
- Add instructions to `APPLY.md` for using `cmake-cooking` with IDEs like CLion

v0.8.0
------
2018-10-05

- Forward the CMake generator to nested calls to `cooking.sh`. This means that if the top-level project is configured with the `Unix Makefiles` generator, then all ingredients which also use `cmake-cooking` will also use `Unix Makefiles`
- Prevent the CMake list-separator of `:` from interfering with environmental variables like `PATH` by switching to use `:::` as the separator
- Switch back to custom targets for stowing files (with improvements)
- Remove the `.cooking_stamp` mechanism, which is no longer necessary
- Refactor CMake code into encapsulated functions wherever possible
- Augment and fix support for synchronizing changes from ingredients on the local file-system. The combination of the new `LOCAL_RECONFIGURE` and `LOCAL_REBUILD` options to `cooking_ingredient` and the `cooking_mark_targets` function allow a developer to work on multiple projects at once and have changes automatically reflected in the "root" project by the build too. See `APPLY.md` for more details

v0.7.0
------
2018-10-01

- Use an `ExternalProject` step to ensure files are stowed rather than a custom target
- Arguments to `cooking_ingredient` which are intended to be forwarded to `ExternalProject_add` are included in a dedicated list with parameter name `EXTERNAL_PROJECT_ARGS`
- Fix a bug that prevented ingredient listings (the `-l` option) from functioning correctly
- Add example projects ("ingredients") in the `pantry` directory for testing and learning
- The build directory (including the default one of `build`) is created relative to the current working-directory of the shell at the time that `cooking.sh` is invoked rather than the directory in which `cooking.sh` is located
- Error messages from `cooking.sh` go to `stderr` correctly
- There is a description of the underlying model of `cmake-cooking` in `UNDERSTAND.md` and an implementation and verification (with unit tests) of this model written in OCaml
- There is a library for invoking `cmake` and `cooking.sh` interactively (written in OCaml) and a new integration test suite
- A `Makefile` exists for conveniently building documentation and running tests
- The memory file written by `cooking.sh` (for recalling past invocations with the `-a` option) is always relative to the current working-directory of the shell rather than the location of `cooking.sh`
- The value of `CMAKE_PREFIX_PATH` is forwarded to nested recipes
- Extra arguments provided to `cooking.sh` after the `--` token are also forwarded to the initial call to `cmake` (for the ingredients)
- The behavior `cooking.sh` with respect to "include" and "exclude" sets matches the model and its implementation in OCaml. The previous behavior was incorrect
- Re-write documentation and add `APPLY.md` to document how to apply `cmake-cooking` to your project

v0.6.0
------
2018-08-27

- Re-license the project with the Apache License 2.0

v0.5.0
------
2018-08-17

- Allow updates by default in ingredients.
- Automatically reconfigure nested local ingredients.

  If an ingredient is specified not with a URL or a `GIT_REPOSITORY` but instead is located on the local file-system (specified via `SOURCE_DIR`), then `cmake-cooking` will now correctly "pick-up" any changes when the ingredient changes.
  
- Allow environmental variables to be set via command-line options.

  Instead of setting environmental variables like
  
      CXX=clang++ ./cooking.sh -r dev
      
  it's now possible to invoke `cmake-cooking` like this:
  
      ./cooking.sh -r dev -s CXX=clang++
      
  This has the advantage that the exact `cmake-cooking`-specific modifications to the environment are known to the script itself (and can be recorded for later).
  
- Allow recalling previous arguments for convenience.

  `cmake-cooking` refreshes the state of the build every time it is invoked. Therefore, when there are many parameters, it can be inconvenient to remember them during every invocation.
  
  Now, one can write something like:
  
      ./cooking.sh -r dev -s CXX=clang++ -- -DMyProject_MAGIC=ONLY
      
  the first time, and the project can be subsequently reconfigured with the same parameters by invoking
  
      ./cooking.sh -a

v0.4.0
------
2018-07-05

- Add the `Cooking_INGREDIENTS_DIR` cache variable.
- Prefix all local variables in macro definitions to avoid conflicts.
- Use GNU Stow to install ingredients to avoid copying files gratuitously.
- Allow available ingredients to be queried with the `-l` option.
- Allow for in-source builds of ingredients which do not support out-of-source builds.
- Disable `UPDATE_COMMAND` by default to avoid unnecessary build steps.
- Improve command-line documentation.
- Allow ingredients to be selectively included or excluded from a recipe for flexibility.
- Allow ingredients to be specified which require their own `cmake-cooking` recipe with the `COOKING_RECIPE` parameter to `cooking_ingredient`.

v0.3.0
------
2018-06-05

- Support specifying the `CMAKE_BUILD_TYPE` with the `-t` option. The build-type gets forwarded to ingredients unless an ingredient overrides it. The default build-type is `Debug`.
- Rename `configure.sh` to `cooking.sh`
- Eliminate the `Cooking_${name}_ROOT_PROJECT` variable.
- Automatically set `CMAKE_INSTALL_PREFIX` for ingredients to further reduce boilerplate.

v0.2.0
------
2018-06-02

- Define `Cooking_${name}_ROOT_PROJECT` instead of `${name}_ROOT_PROJECT`.
- Reduce boilerplate in recipe definitions by making it unnecessary to specify the build and install directories. The source directory of an ingredient can be overridden if necessary.
- Improve the documentation to make it more clear.

v0.1.1
------
2018-05-30

- Correct references to examples in `README.md`.

v0.1.0
-------
2018-05-30

- Initial release.
