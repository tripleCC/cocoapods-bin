# cocoapods-bin

组件二进制化插件。

[基于 CocoaPods 的组件二进制化实践](https://triplecc.github.io/2019/01/21/%E5%9F%BA%E4%BA%8ECocoaPods%E7%9A%84%E7%BB%84%E4%BB%B6%E4%BA%8C%E8%BF%9B%E5%88%B6%E5%8C%96%E5%AE%9E%E8%B7%B5/)

## 概要

本插件所关联的组件二进制化策略：

预先将打包成  `.a` 或者 `.framework` 的组件（目前接入此插件必须使用 `.framework`）保存到静态服务器上，并在 `install` 时，去下载组件对应的二进制版本，以减少组件编译时间，达到加快 App 打包、组件 lint、组件发布等操作的目的。

使用本插件需要提供以下资源：

- 静态资源服务器（可参考 [binary-server](https://github.com/tripleCC/binary-server.git)）
- 源码私有源（保存组件源码版本 podspec）
- 二进制私有源（保存组件二进制版本 podspec）

在所有组件都依赖二进制版本的情况下，本插件支持切换指定组件的依赖版本。

推荐结合 GitLab CI  使用本插件，可以实现自动打包发布，并显著减少其 pipeline 耗时。关于 GitLab CI 的实践，可以参考 [火掌柜 iOS 团队 GitLab CI 集成实践](https://triplecc.github.io/2018/06/23/2018-06-23-ji-gitlabcide-ci-shi-jian/)。虽然后来对部分 stage 和脚本都进行了优化，但总体构建思路还是没变的。

## 准备工作

安装 `cocoapods-bin`：

    $ gem install cocoapods-bin

初始化插件：

```shell
➜  ~ pod bin init

开始设置二进制化初始信息.
所有的信息都会保存在 /Users/songruiwang/.cocoapods/bin.yml 文件中.
你可以在对应目录下手动添加编辑该文件. 文件包含的配置信息样式如下：

---
code_repo_url: git@git.xxxxxx.net:ios/cocoapods-spec.git
binary_repo_url: git@git.xxxxxx.net:ios/cocoapods-spec-binary.git
binary_download_url: http://iosframeworkserver-shopkeeperclient.app.2dfire.com/download/%s/%s.zip
download_file_type: zip


源码私有源 Git 地址
旧值：git@git.xxxxxx.net:ios/cocoapods-spec.git
 >
```

按提示输入源码私有源、二进制私有源、二进制下载地址、下载文件类型后，插件就配置完成了。其中 `binary_download_url` 需要预留组件名称与组件版本占位符，插件内部会依次替换 `%s` 为相应组件的值。

`cococapod-bin` 也支持从 url 下载配置文件，方便对多台机器进行配置：

```shell
➜  ~ pod bin init --bin-url=http://git.xxxxxx.net/qingmu/cocoapods-tdfire-binary-config/raw/master/bin.yml
```

配置文件模版内容如下，根据不同团队的需求定制即可：

```yaml
---
code_repo_url: git@git.xxxxxx.net:ios/cocoapods-spec.git
binary_repo_url: git@git.xxxxxx.net:ios/cocoapods-spec-binary.git
binary_download_url: http://iosframeworkserver-shopkeeperclient.app.2dfire.com/download/%s/%s.zip
download_file_type: zip
```

配置时，不需要手动添加源码和二进制私有源的 repo，插件在找不到对应 repo 时会主动 clone。

插件配置完后，就可以部署静态资源服务器了。对于静态资源服务器，这里不做赘述，只提示一点：在生成二进制 podspec 时，插件会根据 `download_file_type` 设置 source 的 `:type` 字段。在下载 http/https 资源时，CocoaPods 会根据 `:type` 字段的类型采取相应的解压方式，如果设置错误就会抛错。这里提到了 **二进制 podspec 的自动生成**，后面会详细介绍。

这里额外说下打包工具 [cocoapods-packager](https://github.com/CocoaPods/cocoapods-packager) 和 [Carthage](https://github.com/Carthage/Carthage/issues) ，前者可以通过 podspec 进行打包，只要保证 lint 通过了，就可以打成 `.framework`，很方便，但是作者几乎不维护了，后者需要结合组件工程。具体使用哪个可以结合自身团队，甚至可以自己写打包脚本。

## 使用插件

### 基本信息

`cocoapods-bin` 命令行信息可以输入以下命令查看: 

```shell
➜  ~ pod bin --help
Usage:

    $ pod bin [COMMAND]

      组件二进制化插件。利用源码私有源与二进制私有源实现对组件依赖类型的切换。

Commands:

    + init      初始化插件.
    + lib       管理二进制 pod.
    + list      展示二进制 pods .
    > open      打开 workspace 工程.
    + repo      管理 spec 仓库.
    + search    查找二进制 spec.
    + spec      管理二进制 spec.
```

### 二进制 podspec

 `cocoapods-bin` 针对一个组件，同时使用了两种 podspec，分别为源码 podspec 和二进制 podspec，这种方式在没有工具支撑的情况下，势必会增加开发者维护组件的工作量。做为开发者来说，我是不希望同时维护两套 podspec 的。为了解决这个问题， 插件提供了自动生成二进制 podspec 功能，开发者依旧只需要关心源码 podspec 即可。

一般来说，在接入插件前，组件源码 podspec 是已经存在的，所以我们只需要向二进制私有源推送组件的二进制 podspec 即可。如果有条件的话，二进制和源码  podspec 的发布可以走 GitLab CI ，这也是我推荐的做法。

下面介绍下和二进制 podspec 相关的 `cocoapods-bin` 命令。

#### pod bin spec create

```shell
➜  ~ pod bin spec create --help
Usage:

    $ pod bin spec create

      根据源码 podspec 文件，创建对应的二进制 podspec 文件.

Options:

    --platforms=ios                                生成二进制 spec 支持的平台
    --template-podspec=A.binary-template.podspec   生成拥有 subspec 的二进制 spec 需要的模版
                                                   podspec, 插件会更改 version 和 source
    --no-overwrite                                 不允许覆盖
	...
```

`pod bin spec create` 会根据源码 podspec ，创建出二进制 podspec 文件。如果组件存在 subspec ，需要开发者提供 podspec 模版信息，以生成二进制 podspec。插件会根据源码 podspec 更改模版中的 version 字段，并且根据插件配置的 `binary_download_url` 生成 source 字段，最终生成二进制 podspec。

以 A 组件举例，如果 A 的 podspec 如下：

```ruby
Pod::Spec.new do |s|
  s.name             = 'A'
  s.version          = '0.1.0'
  s.summary          = 'business A short description of A.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.homepage         = 'http://git.2dfire-inc.com/ios/A'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'qingmu' => 'qingmu@2dfire.com' }
  s.source           = { :git => 'http://git.2dfire-inc.com/qiandaojiang/A.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'A/Classes/**/*'
  s.public_header_files = 'A/Classes/**/*.{h}'
  s.resource_bundles = {
      'A' => ['A/Assets/*']
  }
end
```

那么生成的 `A.binary.podspec.json` 如下：

```json
{
  "name": "A",
  "version": "0.1.0",
  "summary": "business A short description of A.",
  "description": "TODO: Add long description of the pod here.",
  "homepage": "http://git.2dfire-inc.com/ios/A",
  "license": {
    "type": "MIT",
    "file": "LICENSE"
  },
  "authors": {
    "qingmu": "qingmu@2dfire.com"
  },
  "source": {
    "http": "http://iosframeworkserver-shopkeeperclient.app.2dfire.com/download/A/0.1.0.zip",
    "type": "zip"
  },
  "platforms": {
    "ios": "8.0"
  },
  "source_files": [
    "A.framework/Headers/*",
    "A.framework/Versions/A/Headers/*"
  ],
  "public_header_files": [
    "A.framework/Headers/*",
    "A.framework/Versions/A/Headers/*"
  ],
  "vendored_frameworks": "A.framework",
  "resources": [
    "A.framework/Resources/*.bundle",
    "A.framework/Versions/A/Resources/*.bundle"
  ]
}
```

如果  A 拥有 subspec：

```ruby
Pod::Spec.new do |s|
  s.name             = 'A'
  s.version          = '0.1.0'
  s.summary          = 'business A short description of A.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.homepage         = 'http://git.2dfire-inc.com/ios/A'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'qingmu' => 'qingmu@2dfire.com' }
  s.source           = { :git => 'http://git.2dfire-inc.com/qiandaojiang/A.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'A/Classes/**/*'
  s.public_header_files = 'A/Classes/**/*.{h}'
  s.resource_bundles = {
      'A' => ['A/Assets/*']
  }
  s.subspec 'B' do |ss|
    ss.dependency 'YYModel'
    ss.source_files = 'A/Classes/**/*'
  end
end

```

那么就需要开发者提供 `A.binary-template.podspec`（此模版中的写法假定组件的所有 subspec 都打进一个 `.framework` 里，如果 subpsec 都有属于自己的 `.framework` ，就可以采用其他写法。） ：

```ruby
Pod::Spec.new do |s|
  s.name             = 'A'
  s.summary          = 'business A short description of A.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.homepage         = 'http://git.2dfire-inc.com/ios/A'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'qingmu' => 'qingmu@2dfire.com' }
  s.ios.deployment_target = '8.0'

  s.subspec "Binary" do |ss|
    ss.vendored_frameworks = "#{s.name}.framework"
    ss.source_files = "#{s.name}.framework/Headers/*", "#{s.name}.framework/Versions/A/Headers/*"
    ss.public_header_files = "#{s.name}.framework/Headers/*", "#{s.name}.framework/Versions/A/Headers/*"
    # 结合实际打包后的资源产出文件类型编写
    ss.resources = "#{s.name}.framework/Resources/*.{bundle}", "#{s.name}.framework/Versions/A/Resources/*.{bundle}"
    ss.dependency 'YYModel'
  end

  s.subspec 'B' do |ss|
    ss.dependency "#{s.name}/Binary"
  end
end

```

最终生成的二进制 podspec 如下：

```json
{
  "name": "A",
  "summary": "business A short description of A.",
  "description": "TODO: Add long description of the pod here.",
  "homepage": "http://git.2dfire-inc.com/ios/A",
  "license": {
    "type": "MIT",
    "file": "LICENSE"
  },
  "authors": {
    "qingmu": "qingmu@2dfire.com"
  },
  "platforms": {
    "ios": "8.0"
  },
  "version": "0.1.0",
  "source": {
    "http": "http://iosframeworkserver-shopkeeperclient.app.2dfire.com/download/A/0.1.0.zip",
    "type": "zip"
  },
  "subspecs": [
    {
      "name": "Binary",
      "vendored_frameworks": "A.framework",
      "source_files": [
        "A.framework/Headers/*",
        "A.framework/Versions/A/Headers/*"
      ],
      "public_header_files": [
        "A.framework/Headers/*",
        "A.framework/Versions/A/Headers/*"
      ],
      "resources": [
        "A.framework/Resources/*.{bundle}",
        "A.framework/Versions/A/Resources/*.{bundle}"
      ],
      "dependencies": {
        "YYModel": [

        ]
      }
    },
    {
      "name": "B",
      "dependencies": {
        "A/Binary": [

        ]
      }
    }
  ]
}
```

#### pod bin spec lint

```shell
➜  ~ pod bin spec lint --help
Usage:

    $ pod bin spec lint [NAME.podspec|DIRECTORY|http://PATH/NAME.podspec ...]

      spec lint 二进制组件 / 源码组件

Options:

    --binary                                       lint 组件的二进制版本
    --template-podspec=A.binary-template.podspec   生成拥有 subspec 的二进制 spec 需要的模版
                                                   podspec, 插件会更改 version 和 source
    --reserve-created-spec                         保留生成的二进制 spec 文件
    --code-dependencies                            使用源码依赖进行 lint
    --loose-options                                添加宽松的 options, 包括 --use-libraries
                                                   (可能会造成 entry point (start)
                                                   undefined)
    ...
```

`pod bin spec lint` 默认使用二进制依赖进行 lint，在添加 `--binary` 会去 lint 当前组件的二进制 podspec（动态生成）。在添加 `--code-dependencies` 将会使用源码依赖进行 lint ，个人推荐使用二进制依赖 lint，可以极大地减少编译时间。

#### pod bin repo push 

```shell

➜  ~ pod bin repo push --help
Usage:

    $ pod bin repo push [NAME.podspec]

      发布二进制组件 / 源码组件

Options:

    --binary                                          发布组件的二进制版本
    --template-podspec=A.binary-template.podspec      生成拥有 subspec 的二进制 spec 需要的模版
                                                      podspec, 插件会更改 version 和 source
	--reserve-created-spec                            保留生成的二进制 spec 文件
    --code-dependencies                               使用源码依赖进行 lint
    --loose-options                                   添加宽松的 options, 包括
                                                      --use-libraries (可能会造成 entry
                                                      point (start) undefined)
    ...
```

`pod bin repo push`  用来发布组件，其余特性和 `pod bin spec lint` 一致。

### Podfile DSL

首先，开发者需要在 Podfile 中需要使用 `plugin 'cocoapods-bin'` 语句引入插件 :

```ruby
plugin 'cocoapods-bin'
```

顺带可以删除 Podfile 中的 source ，因为插件内部会自动帮你添加两个私有源。

`cocoapods-bin `插件提供二进制相关的配置语句有 `use_binaries!`、`use_binaries_with_spec_selector!` 以及 `set_use_source_pods`，下面会分别介绍。

#### use_binaries!

全部组件使用二进制版本。

当组件没有二进制版本时，插件会强制工程依赖该组件的源码版本。开发者可以通过执行 `pod install--verbose` option ，在分析依赖步骤查看哪些组件没有二进制版本：

```shell
...
Resolving dependencies of `Podfile`
  【AMapFrameworks | 0.0.4】组件无对应二进制版本 , 将采用源码依赖.
  【ActivityForRestApp | 0.2.1】组件无对应二进制版本 , 将采用源码依赖.
  【AssemblyComponent | 0.5.9】组件无对应二进制版本 , 将采用源码依赖.
  【Bugly | 2.4.6】组件无对应二进制版本 , 将采用源码依赖.
  【Celebi | 0.6.4】组件无对应二进制版本 , 将采用源码依赖.
  【CocoaAsyncSocket/RunLoop | 7.4.3】组件无对应二进制版本 , 将采用源码依赖.
  【CocoaLumberjack | 3.4.1】组件无对应二进制版本 , 将采用源码依赖.
  【CocoaLumberjack/Default | 3.4.1】组件无对应二进制版本 , 将采用源码依赖.
  【CocoaLumberjack/Extensions | 3.4.1】组件无对应二进制版本 , 将采用源码依赖.
  【CodePush | 0.3.1】组件无对应二进制版本 , 将采用源码依赖.
  【CodePush/Core | 0.3.1】组件无对应二进制版本 , 将采用源码依赖.
  【CodePush/SSZipArchive | 0.3.1】组件无对应二进制版本 , 将采用源码依赖.
  【ESExchangeSkin | 0.3.2】组件无对应二进制版本 , 将采用源码依赖.
...
```

也可以通过 Podfile.lock 中的 `SPEC REPOS` 字段，查看哪些组件采用了源码版本，哪些采用了二进制版本：

```yaml
...
SPEC REPOS:
  "git@git.xxxxxx.net:ios/cocoapods-spec-binary.git":
    - AFNetworking
    - Aspects
    - CocoaSecurity
    - DACircularProgress
   ...
  "git@git.xxxxxx.net:ios/cocoapods-spec.git":
    - ActivityForRestApp
    - AMapFrameworks
    - AssemblyComponent
    ...
...
```

#### use_binaries_with_spec_selector!

过滤出需要使用二进制版本组件。

假如开发者只需要 `YYModel` 的二进制版本，那么他可以在 Podfile 中添加以下代码：

```ruby
use_binaries_with_spec_selector! do |spec|
  spec.name == 'YYModel'
end
```

一个实际应用是，三方组件采用二进制版本，团队编写的组件依旧采用源码版本。如果三方组件都在 `cocoapods-repo` 组下，就可以使用以下代码过滤出三方组件：

```ruby
use_binaries_with_spec_selector! do |spec|
 git = spec.source && spec.source['git']
 git && git.include?('cocoapods-repo')
end
```

#### set_use_source_pods

设置使用源码版本的组件。

实际开发中，可能需要查看 YYModel 组件的源码，这时候可以这么设置：

```ruby
set_use_source_pods ['YYModel']
```

如果 CocoaPods 版本为 1.5.3 ，终端会输出以下内容，表示 YYModel 的参照源从二进制私有源切换到了源码私有源：

```shell
Analyzing dependencies
Fetching podspec for `A` from `../`
Downloading dependencies
Using A (0.1.0)
Installing YYModel 1.0.4.2 (source changed to `git@git.xxxxxx.net:ios/cocoapods-spec.git` from `git@git.xxxxxx.net:ios/cocoapods-spec-binary.git`)
Generating Pods project
Integrating client project
Sending stats
Pod installation complete! There is 1 dependency from the Podfile and 2 total pods installed.
```

#### 其他设置

插件默认开启多线程下载组件资源，如果要禁用这个功能，Podfile 添加以下代码即可：

```ruby
install! 'cocoapods', { install_with_multi_threads: true }
```

