# cocoapods-bin

组件二进制化插件。

利用源码私有源与二进制私有源，实现的组件二进制化插件。可通过在 Podfile 中设置 use_binaries!，指定所有组件使用二进制依赖，设置 set_use_source_pods ，指定需要使用源码依赖的组件。

为了兼容源码依赖 subspec 的情况，二进制 specification 的 subspec 需要和源码 specifcation 匹配，二进制的 subspec 比源码 subspec 多也是允许的。

## Installation

    $ gem install cocoapods-bin

## Usage

    $ pod spec bin POD_NAME
