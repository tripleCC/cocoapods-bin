# cocoapods-bin

组件二进制化插件。

利用源码私有源与二进制私有源，实现的组件二进制化插件。可通过在 Podfile 中设置 use_binaries!，指定所有组件使用二进制依赖，设置 set_use_source_pods ，指定需要使用源码依赖的组件。

## Installation

    $ gem install cocoapods-bin

## Usage

    $ pod spec bin POD_NAME
