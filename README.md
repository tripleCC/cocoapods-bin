# cocoapods-bin

组件二进制化插件。

## 概要

本插件所关联的组件二进制化策略：

预先将打包成  `.a` 或者 `.framework` 的组件（接入此插件必须使用 `.framework`）保存到静态服务器上，并在 `install` 时，去下载组件对应的二进制版本，以减少组件编译时间，达到加快 App 打包、组件 lint、组件发布等操作的目的。

使用本插件需要提供以下资源：

- 静态服务器（可参考 [binary-server](https://github.com/tripleCC/binary-server.git)）
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
你可以在对应目录下手动添加编辑该文件. 文件包含的配置信息如下：

---
code_repo_url: 源码私有源 Git 地址，如> git@git.2dfire.net:ios/cocoapods-spec.git
binary_repo_url: 二进制私有源 Git 地址，如> git@git.2dfire.net:ios/cocoapods-spec-binary.git
binary_download_url: 二进制下载地址，内部会依次传入组件名称与版本，替换字符串中的 %s ，如> http://iosframeworkserver-shopkeeperclient.app.2dfire.com/download/%s/%s.zip


源码私有源 Git 地址，如> git@git.2dfire.net:ios/cocoapods-spec.git
旧值：git@git.2dfire.net:ios/cocoapods-spec.git
 >

```

按提示输入源码私有源、二进制私有源、二进制下载地址后，插件就配置完成了。

`cococapod-bin` 也支持从 url 下载配置文件，方便对多台机器进行配置：

```shell
➜  ~ pod bin init --bin-url=http://git.2dfire.net/qingmu/cocoapods-tdfire-binary-config/raw/master/bin.yml
```

配置文件模版内容如下，根据不同团队的需求定制即可：

```yaml
---
code_repo_url: git@git.2dfire.net:ios/cocoapods-spec.git
binary_repo_url: git@git.2dfire.net:ios/cocoapods-spec-binary.git
binary_download_url: http://iosframeworkserver-shopkeeperclient.app.2dfire.com/download/%s/%s.zip
```

配置时，不需要手动添加源码和二进制私有源的 repo，插件在找不到对应 repo 时会主动 clone。

插件配置完后，就可以部署静态服务器了。对于静态服务器，这里不做赘述，只提示一点：**`binary_download_url` 需要以资源类型结尾（例子为 zip 类型）**。

插件为了保证资源类型的多样性，在生成二进制 podspec 时并没有定死 source 的 `:type` 字段，所以 CocoaPods 只能从 url 中获取资源类型。在下载 http/https 资源时，CocoaPods 会根据路径的 extname 检查资源类型，不符合要求的话（zip、tgz、tar、tbz、txz、dmg）就会直接抛错。这里提到了 **二进制 podspec 的自动生成**，后面会详细介绍。

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

Options:

    --silent    Show nothing
    --verbose   Show more debugging information
    --no-ansi   Show output without ANSI codes
    --help      Show help banner of specified command
```

### 二进制 podspec

 `cocoapods-bin` 针对一个组件，同时使用了两种 podspec，分别为源码 podspec 和二进制 podspec，这种方式在没有工具支撑的情况下，势必会增加开发者维护组件的工作量。做为开发者来说，我是不希望同时维护两套 podspec 的。为了解决这个问题， 插件提供了自动生成二进制 podspec 功能，开发者依旧只需要关心源码 podspec 即可。

一般来说，在接入插件前，组件源码 podspec 是已经存在的，所以我们只需要向二进制私有源推送组件的二进制 podspec 即可。如果有条件的话，发布二进制和源码版本可以走 GitLab CI ，这也是我推荐的做法。

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

`pod bin spec create` 会根据源码 podspec ，创建出二进制 podspec 文件。如果组件存在 subspec 时，插件需要开发者提供 podspec 模版信息，以生成二进制 podspec。插件会根据源码 podspec 更改 podspec 模版中的 version 字段，并且根据插件配置的 `binary_download_url` 生成 source 字段，最终生成二进制 podspec。

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
    "http": "http://iosframeworkserver-shopkeeperclient.app.2dfire.com/download/A/0.1.0.zip"
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

那么就需要开发者提供 `A.binary-templte.podspec`（此模版中的写法假定组件的所有 subspec 都打进一个 `.framework` 里，如果 subpsec 都有属于自己的 `.framework` ，就可以采用其他写法。） ：

```ruby
Pod::Spec.new do |s|
  s.name             = 'A'
  s.summary          = 'business A short description of A.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'http://git.2dfire-inc.com/ios/A'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'qiandaojiang' => 'qingmu@2dfire.com' }
  s.ios.deployment_target = '8.0'

  s.subspec "Binary" do |ss|
    ss.vendored_frameworks = "#{s.name}.framework"
    ss.source_files = "#{s.name}.framework/Headers/*", "#{s.name}.framework/Versions/A/Headers/*"
    ss.public_header_files = "#{s.name}.framework/Headers/*", "#{s.name}.framework/Versions/A/Headers/*"
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
    "qiandaojiang": "qingmu@2dfire.com"
  },
  "platforms": {
    "ios": "8.0"
  },
  "version": "0.1.0",
  "source": {
    "http": "http://iosframeworkserver-shopkeeperclient.app.2dfire.com/download/A/0.1.0.zip"
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
      ]
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



### Podfile DSL

