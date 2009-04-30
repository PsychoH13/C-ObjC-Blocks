A Blocks Runtime implementation
===========================================

With the current Leopard-compatible version of Xcode it's not possible to compile this project.
To be able to do so, you need to use the last version of LLVM-GCC that can be downloaded from http://llvm.org/ or the last version of Clang downloadable from http://clang.llvm.org/ .

However, the LLVM-GCC you can download are NOT compatible with the Xcode  LLVM-GCC plugin in Xcode because Apple compiles it its own way to add some options (notably "-arch" option) and thus it cannot be used to compile blocks through Xcode.

A workaround is to use Clang instead, which is fully compatible with the LLVM-GCC Xcode plugin :
1. Simply checkout the sources of Clang and compile them the way indicated by Clang documentations.

2. Go in /Developer/usr/bin directory and rename llvm-gcc-4.2 symbolic link.

3. Add a new symbolic link to your Clang binary and name it llvm-gcc-4.2

4. In Xcode, open your target infos, open Rules tab and set the C source files "using" parameter to LLVM GCC 4.2.
Xcode will then use your symbolic link (connected to the Clang executable) to compile C and ObjC sources.

5. Now to compile blocks you need to tell Clang to do so using -fblocks option, so go in Your project infos, in Build tab, search Other C Flags and add "-fblocks" to the list.

And VOILË, you can compile blocks and use my runtime for tests.

NB: The project settings are already correctly set, so you only need to create the symbolic link.