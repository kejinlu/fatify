# fatify

fatify是一个打包小工具, 通过简单的命令打出iOS，tvOS，watchOS平台下的universal库。

```bash
./fatify.sh project或者workspace路径 schema [ios|tv|watch]
```

----

## 背景介绍
当你需要给别人提供一个静态库或者动态库的，你需要提供的是一个Universal的库，也就是这个library同时包含多个架构的二进制代码，你可以通过`lipo -info`来查看某个library二进制文件包含的所有架构。

```
Luke@LukesMac:/System/Library/Frameworks/Metal.framework » lipo -info Metal
Architectures in the fat file: Metal are: x86_64 i386
```