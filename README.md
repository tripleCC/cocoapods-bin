# cocoapods-bin

组件二进制化插件。

不同于 [cocoapods-tdfire-binary](https://github.com/tripleCC/cocoapods-tdfire-binary) 使用一个私有源，利用在一个 podspec 中添加判断语句实现依赖切换，cocoapods-bin 使用了两个私有源，分别是源码私有源与二进制私有源，并且存储组件对应的源码 podspec 和二进制 podspec。

为什么要使用两个私有源及两个 podspec ？笔者认为的部分好处如下：

1. 更少地侵入 CocoaPods 缓存策略。 在 CocoaPods 中，组件 Cache 名是由 json 化后的 podspec 内容决定的，podspec 执行 json 化这一操作不幂等，会造成 Cache 对应不上。采用 cocoapods-tdfire-binary 中的策略时，在组件本身有二进制版本，但本地 Cache 中没有下载的情况下，需要操作 CocoaPods 的 Cache，以及本地 Pods ，对组件进行更新。而 cocoapods-bin 将这块逻辑都交给 CocoaPods 处理了，只是切换了不同源的两个 podspec 。
2. 更快的首次下载速度。源码依赖只进行 clone 源码操作，二进制依赖只进行 http 下载二进制操作。在大部分组件都是二进制依赖时，较少的 clone 操作可以减少 install 耗时。并且 cocoapods-bin 提供了多线程下载组件的功能，可以极大地提升 install 时 `Downloading dependencies` 的执行速度。
3. 更好的扩展性。拆封成两个 podspec 之后，有利于在二进制 podspec 中处理一些 edge case ，比如拥有较复杂 subspec 的组件。


利用源码私有源与二进制私有源，实现的组件二进制化插件。可通过在 Podfile 中设置 use_binaries!，指定所有组件使用二进制依赖，设置 set_use_source_pods ，指定需要使用源码依赖的组件。

为了兼容源码依赖 subspec 的情况，二进制 specification 的 subspec 需要和源码 specifcation 匹配，二进制的 subspec 比源码 subspec 多也是允许的。

## Installation

    $ gem install cocoapods-bin

## Usage

    $ pod spec bin POD_NAME
