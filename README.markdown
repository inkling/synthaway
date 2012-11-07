# Synthaway: Automatic Removal of @synthesize Directives

Synthaway is a refactoring tool that removes the `@synthesize` directives in
your code base that are no longer needed.

Since Xcode 4.4, when you declare a property in an interface, you don't need
to write a corresponding `@synthesize` in the implementation. The compiler
will do that for you. The synthesized ivar name will have an underscore
followed by the property name.

When you take advantage of this new feature, you may also want to clean up
a bit of your code base by:

*   Removing all those `@synthesize x = _x;` directives
*   Removing all those `@synthesize x;` directives and rename all uses of
    the ivar `x` to `_x`.
    
Removing all those directives may not be trivial if you have a large code
base. There are a few cases where you can't remove them (more on that below),
and manually renaming ivars needs careful review lest it break build.

Synthaway is designed to automate the process. It only removes a
`@synthesize` when it's sound to do so, and it guarantees the renamed ivar
uses are correct.

Synthaway is a Clang-based refactoring tool. It accepts both Objective-C and
Objective-C++ source files.


## Installing Synthaway

To use Synthaway, you have to build it from source. For that, you'll need
the following things:

1. the source code of Synthaway
2. the latest Xcode (4.4 as of writing)
3. CMake
4. the latest Clang *built from source*

We have made a 3-step installation guide as follows. If you already have
CMake and the latest Clang, you can jump to Step 3.

We don't provide pre-built installation packages because all Clang-based 
refactoring tools expect to live at the same directory where Clang is 
(usually `/usr/local/bin`), and although Xcode comes with Clang, installing 
a tool inside your Xcode is a bad idea. Building Clang is not as scary as
it looks, just follow the guide below and you'll have everything up
quickly.


### Installing Synthaway, Step 1 of 3: Getting CMake

[CMake](http://www.cmake.org) is a build tool for many open source software
projects. It's like the old `./configure; make`, but much faster.

You can install CMake using [MacPorts](http://www.macports.org). Once you have
MacPorts installed, install CMake with:

    sudo port install cmake

If you run into any problem installing CMake with port, be sure to update
your MacPorts, then install again:

    sudo port selfupdate
    sudo port install cmake


### Installing Synthaway, Step 2 of 3: Getting and Building Clang

The definitive guide of getting and installing Clang is of course on
[clang.llvm.org](http://clang.llvm.org/get_started.html). You can also take
the shortcut below. This will checkout a copy of LLVM and Clang, create a
build directory, and build and install everything:

    git clone http://llvm.org/git/llvm.git
    cd llvm/tools
    git clone http://llvm.org/git/clang.git
    cd ../../
    mkdir build-llvm
    cd build-llvm
    cmake -DCMAKE_C_COMPILER:STRING=clang ../llvm
    make
    sudo make install
    
Depending on your network and machine, it will take on average 30 minutes to
finish the whole process. You can speed things up by using `make -j2` or
`make -j4` if you have a multicore CPU. If you have a quad-core i7 CPU, you
can actually use `-j8` (it has 8 virtual cores).

**Note on the CMake option we use**: We force CMake to use Clang for the C
compiler because it would by default use gcc, which, depending on
installation, may not support the compiler option `-Wcovered-switch-default`
which is used by some source files in LLVM.


### Installing Synthaway, Step 3 of 3: Building Synthaway

Once you have CMake and Clang in place, building Synthaway is easy. Assuming
you are already in Synthaway's working directory:

    mkdir build
    cd build/
    cmake ../
    make
    
You may also want to run some tests too:

    make test

Then install both `synthaway` and `extract-xcodebuild-log` to
`/usr/local/bin`:

    sudo make install

Note that `/usr/local/bin` is the default and this can be changed when you 
run cmake, but it should be the same directory you've install the Clang that
you just built.

Also, it's not really necessary to have a `build` directory, and you can
just run `cmake .` inside the source directory of Synthaway. But it's a good
practice for using CMake. The advantage is that, if anything goes bad, you
can just zap the whole `build` directory.

Now, if you have followed our instructions thus far, the binary of Synthaway
should be now residing in `/usr/local/bin` at your disposal.

If you want to hack on Synthaway, the next time you want to compile it, you
can just use `make -C ./build/`.

That's it. Now we can start removing some unwanted `@synthesize` directives!


## Using Synthaway

You can use Synthaway to refactor a single `.m` or `.mm` file. The format
is as follows:

    Synthaway <source file> -- <compiler> [compiler options]

For example, if you have the Synthaway binary in the current working
directory, and you want to refactor the `foo.m` in the `tests/` directory:

    synthaway tests/foo.m -- clang -c

The `<compiler>` argument here is usually just `clang`, and the `[compiler
options]` part is usually the options you would pass to the compiler if
you are compiling the source file.

If the source file has no compiler errors and can be refactored, the result
will be written directly to the file. A backup is also written. In our
example, the backup file will be `tests/foo.m.bak`.


## Batch Refactoring Your Code Base

Synthaway is also capable of batch refactoring. Clang-based refactoring tools
like Synthaway recognizes a file called `compile_commands.json`, in which you
can specify the files and their respective compiler commands in your project.
That JSON file is also called a compilation database.

The easiest way to create a compilation database is from the build log of
a `xcodebuild` session. Then, use our tool `extract-xcodebuild-log` to
extract the build log into the database:

    xcodebuild <options> | tee build-log.txt
    extract-xcodebuild-log < build-log.txt > compile_commands.json
    
`extract-xcodebuild-log` can also filter the files that you're interested
in. For example, if you're only interested in refactoring your view
controllers at the moment, use a regular expression:

    extract-xcodebuild-log ".+ViewController.m" < build-log.txt > compile_commands.json

Once you have `compile_commands.json` at the same directory you will run
the tool, you can just throw the files at it:

    synthaway Classes/*.m

### Current Limitation: No Prefix Header Support

Currently precompiled headers are not supported by Synthaway. The 
extraction script `extract-xcodebuild-log` will actually remove prefix header
uses.

This also means that if your source files relies on prefix header, Synthaway
will not be able to refactor them. Usually this can be easily fixed by adding
`#import <UIKit/UIKit.h>` or `#import <Cocoa/Cocoa.h>` to the affected files.

*Note*: It is actually possible to use prefix headers, but it involves some
hacking. A sketch is provided in the "Using Prefix Headers" appendix.


## How Synthaway Works

A `@synthesize` is removed if all of the following conditions are met:

1.  It's not backed by an explicitly declared ivar
2.  The property is not declared in a @protocol
3.  The implementation does not have overidding getter and setter methods
    (in the case of read-only properties, no manual getters)
4.  The ivar name is either the same as the property name or has an
    underscore prefix to the ivar name

If a removed `@synthesize` directive has only the form `@synthesize x;`,
Synthaway will also rename all references to the ivar `x` and change them
to use `_x`.

In the following example, the `@synthesize` for `b` and `c` will be removed,
whereas `p`, `a`, and `d` will be retained.

    @protocol Prop <NSObject>
    @property (retain) NSString *p;
    @end

    @interface Foo : NSObject <Prop>
    {
        NSString *a;
    }
    @property (retain) NSString *a;
    @property (retain) NSString *b;
    @property (retain) NSString *c;
    @property (retain) NSString *d;
    @end
    
    @implementation Foo
    @synthesize p = _p;
    @synthesize a;
    @synthesize b;
    @synthesize c = _c;
    @synthesize d = _d;
    - (void)dealloc
    {
        [_p release];
        [a release];
        [b release];
        [_c release];
        [_d release];
        [super dealloc];
    }
    - (NSString *)d
    {
        return [[_d retain] autoreleased];
    }
    @end
    
Also notice that, after the removal of `@synthesize b;`, every use of the
ivar `b` will be renamed to `_b`. So the `-dealloc` method now becomes:

    - (void)dealloc
    {
        [_p release];
        [a release];
        [_b release];
        [_c release];
        [_d release];
        [super dealloc];
    }


### Repeatedly Refactoring the Same Source File

Once a source file is refactored by Synthaway, any `@synthesize` directive
that can be removed is removed. Therefore repeatedly refactoring the same
file has no further effect. In more technical terms, the refactoring transform
is said to have reached a fixed point.

One thing to note, however, is that if you are using 
`-Wobjc-missing-property-synthesis` (warning against missing property
synthesis), then after refactoring the compiler will complain. You should
remove that flag after refactoring.


### Current Limitation: No Compound `@synthesis` Directives

Currently Synthaway does not handle compound `@synthesis` directives:

    @synthesis a = _a, b, c, d = _d;
    
To make Synthaway work, rewrite compound directives into separate ones:

    @synthesis a = _a;
    @synthesis b;
    @synthesis c;
    @synthesis d = _d;

We have a regular expression-based tool, `expand-synthesize.py`, that can
do this rewriting for you. The script is not included in the installation
process, so you have to find it in the source repository. Since it's
regex-based, it's not going to handle all cases (such as if you have
comments between property names and commas), but it should work well with
a lot of code. The reason we don't do the directive expansion or direct
removal in the refactoring tool itself is just that it adds complexity
to the actual removal process.


## What the Remaining `@synthesize` Reveals

Once the unnecessary `@synthesize` directives are removed, the remaining
ones become a very useful indicator. It may tell you:

*   That you have some properties defined in a protocol
*   That you have some manual getters and setters, which is often an
    indicator of some side effects (e.g. lazy-initialized properties)
*   That you have some synthesized properties with different ivar names
    (e.g. `@synthesize text = _bodyText;`)
*   That you have defined some ivars in the interface: you can remove them
    and feed the source file again to Synthaway if you only target iOS
    or 64-bit Mac

They may also reveal some potential issues. For example:

    @interface MyTextField : UITextField
    @property (assign) MyTextFieldStyle style;
    @end
    
    @implementation MyTextField
    @synthesize style;
    @end
    
Synthaway will not remove the `@synthesize` for you, because `UITextField`
also has a private ivar called `_style`!

Another subtlety (and less of a problem) is when you have overridden a
property, but the superclass does not have an ivar backing:

    #import <UIKit/UIKit.h>

    @interface MyBaseViewController : UIViewController
    @property (retain, readonly) UIView *extraView;
    @end

    @implementation MyBaseViewController
    - (UIView *)extraView
    {
        return nil;
    }
    @end

    @interface MyView : UIView
    @end

    @implementation MyView
    @end

    @interface MySpecialViewController : MyBaseViewController
    @property (retain, readonly) MyView *extraView;
    @end

    @implementation MySpecialViewController
    @synthesize extraView = _extraView;
    - (void)test
    {
        _extraView = nil;
    }
    @end

In this case, the `@synthesize` in `MySpecialViewController` cannot be
removed, because the ivar `_extraView` does not exist in the base class
in the first place. As a general rule, Synthaway is conservative: it will
not remove any `@synthesize` for overriding properties.


## Appendix: Using Prefix Headers

Say your project is built with Xcode 4.4, which comes with its own Clang
installation. Its version is different from the one we built ourselves.
Because of the version difference, Synthaway is not able to refactor files
that rely on prefix headers. That is, if a file doesn't not `#import` all
the headers it needs, Synthaway will report error on that file.

It's actually possible to use prefix headers. It requires some manual
intervention, therefore we only provide a sketch here.

The main idea is to generate the precompiled headers (PCH) from our Clang.
To do so, you need to dive into your `xcodebuild` log, and find the
sections with the keyword `ProcessPCH`.

Then, you have the first clean up the files generated by Xcode's Clang
first. Those files usually reside in either some directories deep down in
`~/Library/Developer/Xcode/DerivedData` or in your project's `./build`.

After you cleaned them up, copy the command a few lines below the 
`ProcessPCH` marker (it'll be an invocation of Clang inside `Xcode.app`),
replace the clang command with something like `/usr/local/bin/clang`. Run
the whole command, and now you'll have the precompiled headers built with
the same version of Clang that Synthaway is based on.

One last step is to modify `extract-xcodebuild-log` and replace this line:

    noPCHCmd = removePCH.sub("", cmd)

with this line:

    noPCHCmd = cmd

This causes the script to keep the prefix header options when it extracts
compiler commands from your build log. Run your modified script (note: not
in `/usr/local/bin`) to generate the `compile_commands.json`. Now Synthaway
will be able to refactor those source files.    


## Copyright and License

Copyright (c) 2012 Inkling Systems, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


## Acknowledgments

A part of Synthaway is based on
[Refactorial](https://github.com/lukhnos/refactorial), a refactoring tool by
Lukhnos Liu and Thomas Minor. The CMake build script, the utility methods in
class `SynthesizeRemovalConsumer`, and the writing out of the rewriter buffer
are derived from their code.
