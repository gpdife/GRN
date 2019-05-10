### 在现有Android工程中接入GRN

1.将GRNDemo中 grnbase， rnSource, repo 目录拷贝至待接入工程顶级目录

<img src="../resources/android_copy.jpg" width="30%"/>

2.配置相关module

引入grnbase, ReactAndroid module

settings.gradle
```
include ':ReactAndroid',':grnbase'
if (!settings.hasProperty("useReactAndroidSource") || Boolean.parseBoolean(useReactAndroidSource)) {
    include ':ReactAndroid'
    project(':ReactAndroid').projectDir = new File(rootProject.projectDir, './rnSource/ReactAndroid')
}
```

将原有项目对ReactNative依赖改为对grn的依赖：
```
dependencies {
    ...
    // implementation "com.facebook.react:react-native:+"  // From node_modules
    implementation project(':grnbase')
    ...
}
```
其中ReactAndroid包含RN官方c++代码，需要配置好NDK环境，且第一次编译比较耗时。

如果没有改动RN底层c++代码的需求，可以直接使用ReactAndroid aar包, 在接入工程顶级目录build.gradle中加入本地仓库：
```
allprojects {
    repositories {
        ...
        maven {
            url = "$rootDir/repo"
        }
        ...
    }
}

```
并在gradle.properties中关闭源码编译开关：
```
useReactAndroidSource=false
```

3.将用GRN-CLI打包的产物添加到assets/webapp目录

<img src="../resources/android_webapp.jpg" width="30%"/>

4.启动逻辑中添加代码处理代码并预加载框架代码，可参考GRNDemo中的启动逻辑:

```
// 安装rn_commom
PackageManager.installPackageForProduct("rn_common");

// 预加载common
GRNInstanceManager.prepareReactInstanceIfNeed();

// 打开GRN页面
GRNURL grnurl = new GRNURL(url);
Intent intent = new Intent(MainActivity.this, GRNBaseActivity.class);
intent.putExtra(GRNBaseActivity.INTENT_COMPONENT_NAME, grnurl);
startActivity(intent);
```
