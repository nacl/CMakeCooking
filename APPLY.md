# Applying `cmake-cooking` to your project

First, it may be useful to understand the [underlying model](./UNDERSTAND.md) for `cmake-cooking.`

We call the description of the dependencies of your project a "recipe". Each dependency described in a recipe is called an "ingredient".

Applying `cmake-cooking` to your project is straightforward provided you adhere to one rule:

## Rule: write a recipe for each direct dependency of your project

To maximize the ability of your project to integrate with other projects and to maximize your ability to change the way you provide dependencies for your project it is important to provide a recipe *for each of the project's direct dependencies*.

We will look at some examples and use them to explain `cmake-cooking`.

Each of the example projects (with food-themed names, which is fitting) are in the top-level `pantry` directory.

### Example: A dependency with no dependencies of its own

The `egg` project has no external dependencies. The same is true of the `durian` project.

Each of these projects can be configured by invoking `cmake`.

However, the `carrot` project depends on both `egg` and `durian` directly.

In the root source directory for `carrot`, we create a file called `cooking_recipe.cmake` with the following contents:

    cooking_ingredient (Durian
      EXTERNAL_PROJECT_ARGS
        SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/extern/durian)

    cooking_ingredient (Egg
      EXTERNAL_PROJECT_ARGS
        SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/extern/egg)
               
The recipe defines two recipes for two ingredients: `Durian` and `Egg`. By convention, we capitalize ingredient names unless they have a well-established lower-case name.

By defining the recipes, we indicate that before we can configure out project, we must (optionally) fetch, configure, build, and install both of these ingredients.

`cmake-cooking` is wrapper over the `ExternalProject` CMake module. This module is very sophisticated and allows us to customize each stage of the process of fetching sources, configuring, building, and installing. `cmake-cooking` provides useful defaults which can be overwritten as necessary. The remaining arguments are forwarded to `ExternalProject_add`.

In these examples, we have used symbolic links in the `pantry` directory to mimic a directory structure in which each of the external dependencies of a project are available as source directories in the `extern` directory.

For example, inside the source tree of `carrot` there are directories `extern/egg` and `extern/durian`.

Therefore, we have specified that the sources are available at this location with `SOURCE_DIR`. In practice, it is particularly useful (and very recommended) to deal with released artifacts at specific version numbers. You can do this by specifying the web address of an archive with the `URL` parameter. Please see the documentation of the `ExternalProject` functions for more information. One advantage of using a path on the local file-system is that you can develop many projects simultaneously and easily integrate changes to the source code of a dependency without having to make a release or install anything (see below for more).

To use `cooking.sh` to execute this recipe, we just issue (in the root source directory of `carrot`):

    ./cooking.sh
    
By default we will build recipes in `Debug` mode and using the `Ninja` CMake generator. There are other options, and you can learn more with the `-h` option.

When executed, both `Egg` and `Durian` will be configured, built, and installed into the `build/_cooking/installed` directory via symbolic links. The actual build files of each ingredient (which the symbolic links point to) are stored in an ingredient-specific directory `build/_cooking/ingredient`. An example is `build/_cooking/ingredient/Durian`.

After this, `Carrot` itself is configured with CMake with an amended search path. `CMakeLists.txt` for `Carrot` verifies that both `Egg` and `Durian` are available and the build succeeds.

#### Passing `cmake` arguments

It is possible to pass arguments directly to invocations of `cmake` by preceeding them with `--`:

    ./cooking.sh -- -DCarrot_PEEL=ON -DEgg_SCRAMBLE=OFF
    
#### Including and excluding ingredients
    
We can use `cmake-cooking` to supply only some external dependencies if we wish to supply some dependencies through different means (like system packages).

The `-e` ("exclude") and `-i` ("include") options allow us to do this.

For example, if we wish to use `Egg` installed in some other fashion we can exclude it from our recipe:

    ./cooking.sh -e Egg

### Example: A dependency with its own dependencies

We may have a dependency with its own external dependencies.

In this case, we specify a recipe that recursively invokes `cooking.sh` for the dependency instead of configuring with `cmake`. We do this by including the `COOKING_RECIPE` argument to `cooking_ingredient`.

For example, consider the `Banana` project:

    cooking_ingredient (Durian
      EXTERNAL_PROJECT_ARGS
        SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/extern/durian)

    cooking_ingredient (Carrot
      COOKING_RECIPE <DEFAULT>
      REQUIRES Durian
      EXTERNAL_PROJECT_ARGS
        SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/extern/carrot)

`Banana` has two direct dependencies: `Durian` and `Carrot`.

`Durian` has no dependencies, so we specify it just as we did for `Carrot`.

*Importantly*, we directly depend on `Carrot` but `Carrot` also directly depends on `Durian`. However, *our recipes must include each ingredient only once*.

To fix this, we use the `REQUIRES` argument in the recipe for `Carrot`. This does two things. The first is that it ensures that `Durian` is executed before `Carrot`. The second is that any recipe for `Durian` inside of `Carrot` is *ignored*. Logically, we are indicating that `Durian` is provided by us and `Carrot` should not provide it itself.

In this way, we can build arbitrary acyclic graphs of dependencies with recipes with maximal flexibility in terms of how we provide each ingredient.

#### ExternalProject Arguments

When using ingredients with dependencies of their own, many normal configuration-related `EXTERNAL_PROJECT_ARGS` will not function, given that CMakeCooking overrides the `CONFIGURE_COMMMAND` argument passed to `ExternalProject_add`.  Typically, you'll usually need to tweak the `cmake` args that Cooking will eventually use.  This can usually be accomplished with the `CMAKE_ARGS` argument.

With recipes that have ingredients that do not use Cooking themselves, the full suite of configuration-related `ExternalProject` args is available.  Such recipes will pass `CONFIGURE_COMMAND` to `ExternalProject_add` only if it is provided.

### Using `cmake-cooking` with integrated development environments (IDEs)

It is very easy to use `cmake-cooking` with IDEs which offer CMake support. A good example is CLion from JetBrains.

Usually these IDEs have configuration options for specifying how the IDE invokes CMake internally.

First, invoke `cooking.sh` from a terminal window as you would without an IDE. This will, by default, create the `build` directory.

Configure your IDE to use a *different* build directory for its CMake products: for example, `build-clion`.

Then, amend the `CMAKE_PREFIX_PATH` to point to the directory of the installed ingredients. That is, instruct your IDE to invoke CMake as follows:

    cmake -DCMAKE_PREFIX_PATH=${PATH_TO_SOURCE_DIR}/build/_cooking/installed # ... other options here ...

Any time you need to reconfigure your project to account for its dependencies, run `cooking.sh` from the terminal window. Otherwise, the IDE should be able to configure and build the project without any knowledge of `cmake-cooking`.

### Developing many ingredients locally

If an ingredient specifies `SOURCE_DIR` with a path to a directory on the local file-system, then the source code will be copied over once to a project-specific location by `cooking.sh`. This means that if the source code of the ingredient changes, these changes will *not* be incorporated into the project during re-compilation.

To support work-flows in which many projects are worked-on simultaneously, the `LOCAL_REBUILD` and `LOCAL_RECONFIGURE` options are available.

Suppose there is a project in `~/src/support_library` and a project `~/src/my_app`.

In `~/src/my_app/cooking_recipe.cmake` we have

    cooking_ingredient (SupportLibrary
      LOCAL_RECONFIGURE
      EXTERNAL_PROJECT_ARGS
        SOURCE_DIR ${HOME}/src/support_library)

Since we have specified `LOCAL_RECONFIGURE`, every time we re-run `cooking.sh` for `my_app` it will cause `SupportLibrary` to be re-configured, re-built, and re-installed locally. That is, any changes in `~/src/support_library` will be reflected automatically.

The same would have been true if we had replaced `LOCAL_RECONFIGURE` with `LOCAL_REBUILD`, except that `SupportLibrary` would always be re-built instead of always being re-configured.

*Note*: An ingredient marked with `LOCAL_REBUILD` does not get rebuilt when the build-tool (like `ninja` or `make`) is invoked; only when `cooking.sh` is re-run.

## Preliminary guidelines

While `cmake-cooking` is a relatively new system, the following guidelines (with the *strong* recommendation of the approach to dependencies described above) should help to improve work-flows:

- If an external dependency is tracked at the level of a particular commit (ie, in Git) then include it in your project as a Git submodule and indicate its location in a recipe with `SOURCE_DIR`
- For external dependencies tracked at the level of a particular release (eg, `Boost` at version `1.67`), use the `URL` argument to point to a release archive (like a `zip` or `tarball`). This will establish a static set of dependency versions that are known to work together and limit the amount of work the build-system has to do in re-configuring and recompiling dependencies
- If your work-flow encompasses working on many inter-related projects at once then you can -- for the purposes of development on your local machine only -- replace any existing "fetch" methods with `SOURCE_DIR` and the location of the dependency on your file-system. This will mean that changes in dependencies on your file-system will be reflected in your project automatically when it is compiled
