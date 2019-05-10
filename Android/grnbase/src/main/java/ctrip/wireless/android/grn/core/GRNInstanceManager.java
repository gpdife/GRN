/*
 * Copyright Ctrip.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package ctrip.wireless.android.grn.core;

import android.net.Uri;
import android.preference.PreferenceManager;
import android.text.TextUtils;
import android.util.DisplayMetrics;
import android.widget.Toast;

import com.facebook.react.ReactInstanceManager;
import com.facebook.react.ReactInstanceManagerBuilder;
import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.common.LifecycleState;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.uimanager.DisplayMetricsHolder;

import java.io.File;
import java.util.ArrayList;

import ctrip.grn.instance.GRNInstanceInfo;
import ctrip.grn.instance.GRNInstanceState;
import ctrip.grn.instance.GRNLoadReportListener;
import ctrip.grn.instance.GRNPageInfo;
import ctrip.grn.instance.GRNReactContextLoadedListener;
import ctrip.grn.utils.ReactNativeJson;
import ctrip.wireless.android.grn.extend.GRNProvider;
import ctrip.wireless.android.grn.ContextHolder;
import ctrip.wireless.android.grn.utils.FileUtil;
import ctrip.wireless.android.grn.utils.LogUtil;
import ctrip.wireless.android.grn.utils.StringUtil;
import ctrip.wireless.android.grn.utils.ThreadUtils;

public class GRNInstanceManager {


    /**
     * interface InitReactNativeCallBack
     */
    public interface ReactInstanceLoadedCallBack {

        /**
         * callback instance and status
         * @param instanceManager instanceManager
         * @param status instance状态码
         */
        void onReactInstanceLoaded(ReactInstanceManager instanceManager, int status);

    }

    private static final String REQUIRE_BUSINESS_MODULE_EVENT = "requirePackageEntry";
    private static final String PREFS_DEBUG_SERVER_HOST_KEY = "debug_http_host";
    private final static String CONTAINER_VIEW_RELEASE_MESSAGE = "containerViewDidReleased";

    private static ArrayList<String> mInUsedGRNProduct = new ArrayList<>();

    /**
     * 所有Instance性能监控回调
     */
    private static GRNLoadReportListener mPerformanReportListener = new GRNLoadReportListener() {
        @Override
        public void onLoadComponentTime(ReactInstanceManager mng, long renderTime) {
            // TODO 业务开始渲染回调
        }
    };

    /**
     * 预创建ReactInstanceManager
     */
    public static void prepareReactInstanceIfNeed() {
        int readyCount = GRNInstanceCacheManager.getCacheCommonReactInstanceCount();
        if (readyCount >= 2) {
            LogUtil.e("GRN Instance ready count ="+readyCount);
            return;
        }

        ThreadUtils.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                GRNInstanceInfo grnInstanceInfo = new GRNInstanceInfo();
                grnInstanceInfo.businessURL = GRNURL.COMMON_BUNDLE_PATH;
                grnInstanceInfo.instanceState = GRNInstanceState.Loading;
                grnInstanceInfo.errorReportListener = GRNErrorHandler.getErrorReportListener();
                grnInstanceInfo.loadReportListener = mPerformanReportListener;
                createBundleInstance(new GRNURL(GRNURL.COMMON_BUNDLE_PATH), null, grnInstanceInfo, null);
            }
        }, 1000);
    }

    /**
     * 创建OnlineBundle、CacheUnbundle、AllUnbundle统一入口
     * @param rnURL rnURL
     * @param bundleScript bundleScript
     * @param grnInstanceInfo grnInstanceInfo
     * @param callBack callBack
     * @return ReactInstanceManagerpre
     */
    private static ReactInstanceManager createBundleInstance(final GRNURL rnURL,
                                                             String bundleScript,
                                                             GRNInstanceInfo grnInstanceInfo,
                                                             final ReactInstanceLoadedCallBack callBack) {

        if (rnURL == null || TextUtils.isEmpty(rnURL.getUrl())) {
            //极少，没有该错误
            callBack.onReactInstanceLoaded(null, -201);
            return null;
        }

        final boolean isOnlineBundle = rnURL.getRnSourceType() == GRNURL.SourceType.Online ;
        final boolean isNormalBundle = !isOnlineBundle && !TextUtils.isEmpty(bundleScript);
        final boolean isCommonBundle = GRNURL.COMMON_BUNDLE_PATH.equalsIgnoreCase(rnURL.getUrl());
        final boolean isUnbundleBizURL =  rnURL.isUnbundleURL();
        final boolean isGRNUnbundle = isCommonBundle || isUnbundleBizURL;

        ReactInstanceManagerBuilder builder = ReactInstanceManager.builder();
        builder.setApplication(ContextHolder.application);
        builder.setInitialLifecycleState(LifecycleState.BEFORE_CREATE);
        builder.setGRNInstanceInfo(grnInstanceInfo);
        for (ReactPackage reactPackage: GRNProvider.provideReactPackages()) {
            builder.addPackage(reactPackage);
        }

        if (isOnlineBundle) {
            builder.setUseDeveloperSupport(true);
            builder.setJSMainModulePath("index");
            builder.setBundleScript(bundleScript, rnURL.getUrl(), false);
            Uri uri = Uri.parse(rnURL.getUrl());
            String debugUrl = uri.getHost() + ":" + (uri.getPort() == -1 ? 80 : uri.getPort());
            PreferenceManager.getDefaultSharedPreferences(ContextHolder.context)
                    .edit().putString(PREFS_DEBUG_SERVER_HOST_KEY, debugUrl).apply();
        }
        else if (isNormalBundle) {
            builder.setUseDeveloperSupport(false);
            builder.setBundleScript(bundleScript, rnURL.getUrl(), false);
            builder.setNativeModuleCallExceptionHandler(GRNErrorHandler.getNativeExceptionHandler());
            PreferenceManager.getDefaultSharedPreferences(ContextHolder.context)
                    .edit().remove(PREFS_DEBUG_SERVER_HOST_KEY).apply();
        }
        else if (isGRNUnbundle){
            builder.setUseDeveloperSupport(false);
            builder.setJSBundleFile(GRNURL.COMMON_BUNDLE_PATH);
            builder.setNativeModuleCallExceptionHandler(GRNErrorHandler.getNativeExceptionHandler());
            PreferenceManager.getDefaultSharedPreferences(ContextHolder.context)
                    .edit().remove(PREFS_DEBUG_SERVER_HOST_KEY).apply();
        }
        final ReactInstanceManager instanceManager = builder.build();
        instanceManager.setReactContextLoadedListener(new GRNReactContextLoadedListener() {
            boolean isInstanceLoaded = false;

            @Override
            public void onReactContextLoaded(ReactInstanceManager reactInstance) {
                if (ContextHolder.debug) {
                    if (isInstanceLoaded) {
                        return;
                    }
                    isInstanceLoaded = true;
                }
                int resultStatus = 0;
                if (reactInstance == null || reactInstance.getGRNInstanceInfo() == null || reactInstance.getCatalystInstance() == null)  {
                    resultStatus = -301;
                }
                else if (reactInstance.getGRNInstanceInfo().instanceState == GRNInstanceState.Error) {
                    resultStatus = -505;
                }
                else {
                    GRNInstanceInfo instanceInfo = reactInstance.getGRNInstanceInfo();
                    if (isOnlineBundle || isNormalBundle) {
                        instanceInfo.instanceState = GRNInstanceState.Dirty;
                        reactInstance.getCatalystInstance().setSourceURL(rnURL.getUrl());
                    } else if (isGRNUnbundle) {
                        if (isUnbundleBizURL) {
                            instanceInfo.instanceState = GRNInstanceState.Ready;
                            GRNUnbundlePackage unbundlePackage = new GRNUnbundlePackage(rnURL);
                            if (unbundlePackage.getModuleConfigHashMap() == null || unbundlePackage.getModuleConfigHashMap().isEmpty()) {
                                //极少，无此错误
                                resultStatus = -305;
                            } else {
                                reactInstance.getCatalystInstance().setGRNModuleIdConfig(unbundlePackage.getModuleConfigHashMap());
                                resultStatus = emitReRenderMessage(reactInstance, unbundlePackage.getMainModuleId(), rnURL.getUrl(), false);
                            }
                        } else {
                            instanceInfo.instanceState = GRNInstanceState.Ready;
                            resultStatus = -306;
                        }

                        cacheReactInstance(reactInstance);
                    }
                }

                if (callBack != null) {
                    callBack.onReactInstanceLoaded(reactInstance, resultStatus);
                }
            }
        });
        instanceManager.createReactContextInBackground();
        return instanceManager;
    }

    /**
     * 构建在线onlineBundle
     * @param rnURL rnURL
     * @param callBack callBack
     */
    private static ReactInstanceManager createOnlineReactInstance(GRNURL rnURL, ReactInstanceLoadedCallBack callBack) {
        File file = new File(ContextHolder.context.getFilesDir(), "ReactNativeDevBundle.js");
        if (file.exists()) {
            file.delete();
        }
        GRNInstanceInfo grnInstanceInfo = new GRNInstanceInfo();
        grnInstanceInfo.businessURL = rnURL.getUrl();
        grnInstanceInfo.instanceState = GRNInstanceState.Loading;
        grnInstanceInfo.originalInstanceStatus = GRNInstanceState.Loading;
        grnInstanceInfo.errorReportListener = GRNErrorHandler.getErrorReportListener();
        grnInstanceInfo.loadReportListener = mPerformanReportListener;
        return createBundleInstance(rnURL, "{}", grnInstanceInfo, callBack);
    }


    /**
     * 获取ReactInstanceManager
     * @param rnURL rnURL
     * @param callBack callBack
     */
    public static ReactInstanceManager getReactInstance(final GRNURL rnURL, GRNPageInfo grnPageInfo, final ReactInstanceLoadedCallBack callBack) {
        ReactInstanceManager reactInstance = null;
        int errorStatus = 0;
        boolean needCallbackRightNow = false;
        if (rnURL == null || !GRNURL.isGRNURL(rnURL.getUrl())) {
            if (rnURL == null) {
                errorStatus = -101;
            } else if (!GRNURL.isGRNURL(rnURL.getUrl())) {
                errorStatus = -102;
            }
            needCallbackRightNow = true;
        } else if (rnURL.getRnSourceType() == GRNURL.SourceType.Online) {
            reactInstance = createOnlineReactInstance(rnURL, callBack);
        } else {
            String grnURLStr = rnURL.getUrl();
            if(rnURL.isUnbundleURL()) { //unbundle格式，处理cache策略
                ReactInstanceManager readyCachedInstance = null;
                ReactInstanceManager dirtyCachedInstance = null;

                ReactInstanceManager readyToUseInstance = GRNInstanceCacheManager.getInstanceIfExist(rnURL);
                if (readyToUseInstance != null) {
                    if (readyToUseInstance.getGRNInstanceInfo().instanceState == GRNInstanceState.Dirty) {
                        dirtyCachedInstance = readyToUseInstance;
                    } else if (readyToUseInstance.getGRNInstanceInfo().instanceState == GRNInstanceState.Ready) {
                        readyCachedInstance = readyToUseInstance;
                    }
                }

                GRNUnbundlePackage unbundlePackage = new GRNUnbundlePackage(rnURL);
                if (dirtyCachedInstance != null) {
                    reactInstance = dirtyCachedInstance;
                    reactInstance.getGRNInstanceInfo().originalInstanceStatus = GRNInstanceState.Dirty;
                    reactInstance.getGRNInstanceInfo().countTimeoutError = 0;
                    reactInstance.getGRNInstanceInfo().countJSFatalError = 0;
                    reactInstance.getGRNInstanceInfo().countLogFatalError = 0;
                    reactInstance.getGRNInstanceInfo().countNativeFatalError = 0;
                    needCallbackRightNow = true;
                } else if (readyCachedInstance != null) {
                    if (unbundlePackage.getModuleConfigHashMap() == null || unbundlePackage.getModuleConfigHashMap().isEmpty()) {
                        errorStatus = -103;
                    } else {
                        readyCachedInstance.getGRNInstanceInfo().businessURL = grnURLStr;
                        readyCachedInstance.getGRNInstanceInfo().isUnbundle = true;
                        readyCachedInstance.getGRNInstanceInfo().inUseProductName = rnURL.getProductName();
                        readyCachedInstance.getGRNInstanceInfo().loadReportListener = mPerformanReportListener;
                        readyCachedInstance.getGRNInstanceInfo().errorReportListener = GRNErrorHandler.getErrorReportListener();
                        readyCachedInstance.getCatalystInstance().setGRNModuleIdConfig(unbundlePackage.getModuleConfigHashMap());
                        readyCachedInstance.getGRNInstanceInfo().originalInstanceStatus = GRNInstanceState.Ready;
                        int emitMsgRet = emitReRenderMessage(readyCachedInstance, unbundlePackage.getMainModuleId(), grnURLStr, true);
                        if (emitMsgRet == 0) {
                            errorStatus = 0;
                            reactInstance = readyCachedInstance;
                        } else {
                            errorStatus = -104;
                        }

                        //Ready的被使用了，预创建
                        prepareReactInstanceIfNeed();
                    }

                    needCallbackRightNow = true;
                }
            }

            if (reactInstance == null && errorStatus == 0) {
                GRNInstanceInfo instanceInfo = new GRNInstanceInfo();
                instanceInfo.isUnbundle = true;
                instanceInfo.businessURL = grnURLStr;
                instanceInfo.originalInstanceStatus = GRNInstanceState.Loading;
                instanceInfo.instanceState = GRNInstanceState.Loading;
                instanceInfo.inUseProductName = rnURL.getProductName();
                instanceInfo.loadReportListener = mPerformanReportListener;
                instanceInfo.errorReportListener = GRNErrorHandler.getErrorReportListener();
                String bundleScript = null;
                if(!rnURL.isUnbundleURL()) {
                    bundleScript = FileUtil.readFileAsString(new File(rnURL.getAbsoluteFilePath()));
                }
                reactInstance = createBundleInstance(rnURL, bundleScript, instanceInfo, callBack);
                if (reactInstance == null) {
                    errorStatus = -105;
                }
            }
        }

        if (ContextHolder.debug && errorStatus != 0) {
            Toast.makeText(ContextHolder.context
                    , "createReactInstance error: status=" + errorStatus
                    , Toast.LENGTH_SHORT).show();
        }

        if (reactInstance != null && reactInstance.getGRNInstanceInfo() != null) {
            reactInstance.getGRNInstanceInfo().countTimeoutError = 0;
            reactInstance.getGRNInstanceInfo().countJSFatalError = 0;
            reactInstance.getGRNInstanceInfo().countLogFatalError = 0;
            reactInstance.getGRNInstanceInfo().countNativeFatalError = 0;
        }

        if (needCallbackRightNow) {
            callBack.onReactInstanceLoaded(reactInstance, errorStatus);
        }

        cacheReactInstance(reactInstance);

        return reactInstance;
    }

    /**
     * 缓存创建好的ReactInstanceManager
     * @param manager manager
     */
    private static void cacheReactInstance(ReactInstanceManager manager) {
        GRNInstanceCacheManager.cacheReactInstanceIfNeed(manager);
    }

    /**
     * 离开RN容器页面，减少ReactInstanceManager的引用计数
     * @param  manager manager
     */
    public static void decreaseReactInstanceRetainCount(ReactInstanceManager manager, GRNURL grnurl) {
        synchronized (GRNInstanceManager.class) {
            if (manager != null && manager.getGRNInstanceInfo() != null) {
                manager.getGRNInstanceInfo().inUseCount -= 1;
                GRNInstanceCacheManager.performLRUCheck();
            }
        }
    }

    /**
     * 进入RN容器页面，增加ReactInstanceManager的引用计数
     * @param manager manager
     */
    public static void increaseReactInstanceRetainCount(ReactInstanceManager manager) {
        synchronized (GRNInstanceManager.class) {
            if (manager != null && manager.getGRNInstanceInfo() != null) {
                manager.getGRNInstanceInfo().inUseCount += 1;
            }
        }
    }

    /**
     * 重置无法使用Dirty状态下的instance为error
     * @param url url
     */
    public static void invalidateDirtyBridgeForURL(GRNURL url) {
        GRNInstanceCacheManager.invalidateDirtyBridgeForURL(url);
    }

    /**
     * Unbundle包，通知重新刷新页面
     * @param mng mng
     * @param mainModuleId mainModuleId
     */
    private static int emitReRenderMessage(ReactInstanceManager mng, String mainModuleId, String businessUrl, boolean fromCache) {
        int status = 0;
        if (TextUtils.isEmpty(mainModuleId)) {
            mainModuleId = "666666";
        }

        if (mng.getGRNInstanceInfo() == null) {
            status = -104;
        }

        if (status == 0) {
            if (businessUrl != null && businessUrl.contains("?")) {
                mng.setModulePath(businessUrl.substring(0, businessUrl.lastIndexOf("?")));
            } else {
                mng.setModulePath(businessUrl);
            }
            com.alibaba.fastjson.JSONObject params = new com.alibaba.fastjson.JSONObject();
            params.put("moduleId", mainModuleId);
            params.put("packagePath", businessUrl == null ? "" : businessUrl);
            params.put("productName", mng.getGRNInstanceInfo().inUseProductName);
            if (!emitDeviceEventMessage(mng, REQUIRE_BUSINESS_MODULE_EVENT, ReactNativeJson.convertJsonToMap(params))) {
                status = -103;
            }

        }
        mng.getGRNInstanceInfo().instanceState = GRNInstanceState.Dirty;
        return status; //status 不为0，后续invokeError会将mng状态设置为Error
    }

    /**
     * emit message
     * @param instanceManager instanceManager
     * @param paramMap paramMap
     */
    public static boolean emitDeviceEventMessage(ReactInstanceManager instanceManager, String eventName, WritableMap paramMap) {
        if (!isReactInstanceReady(instanceManager)) {
            return false;
        }
        try {
            if (instanceManager.getCurrentReactContext() != null){
                instanceManager.getCurrentReactContext()
                        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                        .emit(eventName, paramMap);
            }
        } catch (Exception ex) {
            return false;
        }
        return true;
    }

    /**
     * check current instance could be used
     * @param instanceManager instanceManager
     */
    public static boolean isReactInstanceReady(ReactInstanceManager instanceManager) {
        if (instanceManager != null && instanceManager.getGRNInstanceInfo() != null ) {
            GRNInstanceInfo grnInfo = instanceManager.getGRNInstanceInfo();
            if (grnInfo.instanceState == GRNInstanceState.Dirty ||
                    grnInfo.instanceState == GRNInstanceState.Ready) {
                if (grnInfo.countJSFatalError > 0 || grnInfo.countLogFatalError > 0 || grnInfo.countNativeFatalError > 0 || grnInfo.countTimeoutError > 0) {
                    return false;
                }
                return true;
            }
        }
        return false;
    }

    /**
     * 进入GRNPage
     * @param grnurl grn业务Url
     */
    public static void enterGRNPage(ReactInstanceManager reactInstanceManager, GRNURL grnurl) {
        if (grnurl != null && grnurl.getProductName() != null) {
            mInUsedGRNProduct.add(grnurl.getProductName());
        }
        GRNInstanceManager.increaseReactInstanceRetainCount(reactInstanceManager);
    }

    /**
     * 离开GRNPage
     * @param grnurl grn业务Url
     */
    public static void exitGRNPage(ReactInstanceManager mReactInstanceManager, GRNURL grnurl) {
        if (grnurl != null && grnurl.getProductName() != null) {
            int outPageIndex = mInUsedGRNProduct.lastIndexOf(grnurl.getProductName());
            if (outPageIndex != -1 && outPageIndex >= 0 && outPageIndex < mInUsedGRNProduct.size() ) {
                mInUsedGRNProduct.remove(outPageIndex);
            }
        }
        if (mReactInstanceManager != null) {
            GRNInstanceManager.emitDeviceEventMessage(mReactInstanceManager, CONTAINER_VIEW_RELEASE_MESSAGE, null);
            GRNInstanceManager.decreaseReactInstanceRetainCount(mReactInstanceManager, grnurl);
        }
    }

    /**
     * 查询当前业务是否有使用的Page
     * @param url url
     */
    public static boolean hasGRNPage(GRNURL url) {
        if (url == null || TextUtils.isEmpty(url.getProductName())) {
            return false;
        }
        for (String productName : mInUsedGRNProduct) {
            if (StringUtil.equalsIgnoreCase(productName, url.getProductName())) {
                return true;
            }
        }
        return false;
    }


}

