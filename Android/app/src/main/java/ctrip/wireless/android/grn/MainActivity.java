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
package ctrip.wireless.android.grn;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.v4.content.ContextCompat;
import android.support.v7.app.AppCompatActivity;
import android.text.TextUtils;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.Spinner;
import android.widget.Switch;
import android.widget.Toast;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import ctrip.wireless.android.grn.core.GRNInstanceManager;
import ctrip.wireless.android.grn.core.GRNURL;
import ctrip.wireless.android.grn.core.PackageManager;
import ctrip.wireless.android.grn.utils.FileUtil;

public class MainActivity extends AppCompatActivity {

    Spinner spinner;
    Spinner rnSpinner;
    ListView onlineListView;
    ArrayAdapter simpleAdapter;
    SharedPreferences localSP;

    private static final String GRN_DEMO_SP_NAME = "grnDemoSP";
    private static final String GRN_DEMO_PRELOAD_COMMON = "PreloadCommon";
    private static final String GRN_DEMO_ADDRESS_LIST = "addressList";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        localSP = getSharedPreferences(GRN_DEMO_SP_NAME, Context.MODE_PRIVATE);

        // 测试使用：删除webapp目录
        FileUtil.delDir(PackageManager.getFileWebappPath());

        // 安装rn_commom
        PackageManager.installPackageForProduct("rn_common");

        if (localSP.getBoolean(GRN_DEMO_PRELOAD_COMMON, true)) {
            GRNInstanceManager.prepareReactInstanceIfNeed();
        }

        setContentView(R.layout.activity_main);
        requestSystemAlertWindow();
        initViews();
        gotoLocalConfigIfOk();
    }

    private void initViews() {
        spinner = findViewById(R.id.grnBundleSpinner);
        rnSpinner = findViewById(R.id.rnBundleSpinner);

        initSpinner();

        findViewById(R.id.loadGRN).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                PackageManager.installPackageForProduct(spinner.getSelectedItem() + "");
                startGRNBaseActivity("/" + spinner.getSelectedItem() + "/_grn_config?GRNModuleName=GRNApp&GRNType=1");
            }
        });

        findViewById(R.id.loadRN).setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View view) {
                PackageManager.installPackageForProduct(rnSpinner.getSelectedItem() + "");
                startGRNBaseActivity("/" + rnSpinner.getSelectedItem() + "/main.js?GRNModuleName=RNTesterApp&GRNType=1");
            }
        });

        final EditText onlineUrlText = findViewById(R.id.customUrl);
        findViewById(R.id.gotoCustomUrl).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                String onlineUrl = onlineUrlText.getText().toString();
                if (!TextUtils.isEmpty(onlineUrl)) {
                    onlineClick(onlineUrl);
                }
            }
        });

        initOnlineList();

        Switch preloadSwitch = findViewById(R.id.preloadCommon);
        boolean preloadCommon = localSP.getBoolean(GRN_DEMO_PRELOAD_COMMON, true);
        preloadSwitch.setChecked(preloadCommon);
        preloadSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton compoundButton, boolean open) {
                localSP.edit().putBoolean(GRN_DEMO_PRELOAD_COMMON, open).commit();
                Toast.makeText(MainActivity.this, "已" + (open ? "打开" : "关闭") +  "GRN预加载，重启APP生效", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void initOnlineList() {
        onlineListView = findViewById(R.id.onlineList);
        List<String> list = new ArrayList<>();
        String listString = localSP.getString(GRN_DEMO_ADDRESS_LIST, "");
        if (!TextUtils.isEmpty(listString)) {
            list.addAll(Arrays.asList(listString.split(",")));
        }
        simpleAdapter = new ArrayAdapter(this, R.layout.grn_spinner_item, list);
        onlineListView.setAdapter(simpleAdapter);
        onlineListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> adapterView, View view, int i, long l) {
                startGRNBaseActivity((String) simpleAdapter.getItem(i));
            }
        });
    }

    private void initSpinner() {
        try {
            String[] webappDirs = getAssets().list("webapp");
            List<String> grnBundles = new ArrayList<>();
            List<String> rnBundles = new ArrayList<>();
            for (String webappDir : webappDirs) {
                if (webappDir.toLowerCase().contains("_grn")) {
                    grnBundles.add(webappDir);
                } else if (webappDir.toLowerCase().contains("_rn")) {
                    rnBundles.add(webappDir);
                }
            }
            Collections.reverse(grnBundles);
            Collections.reverse(rnBundles);
            ArrayAdapter<CharSequence> adapter = new ArrayAdapter(this, R.layout.grn_spinner_item, grnBundles.toArray(new String[grnBundles.size()])) {
                public View getView(int position, View convertView, ViewGroup parent) {
                    View view = super.getView(position, convertView, parent);
                    view.setPadding(0, view.getPaddingTop(),view.getPaddingRight(),view.getPaddingBottom());
                    return view;
                }
            };

            spinner.setAdapter(adapter);

            ArrayAdapter<CharSequence> rnAdapter = new ArrayAdapter(this, R.layout.grn_spinner_item, rnBundles.toArray(new String[rnBundles.size()])) {
                public View getView(int position, View convertView, ViewGroup parent) {
                    View view = super.getView(position, convertView, parent);
                    view.setPadding(0, view.getPaddingTop(),view.getPaddingRight(),view.getPaddingBottom());
                    return view;
                }
            };
            rnSpinner.setAdapter(rnAdapter);
        } catch (IOException e) {
            e.printStackTrace();
        }

    }

    private void onlineClick(String onlineUrl) {
        addToLocalUrls(onlineUrl);
        startGRNBaseActivity(onlineUrl);
    }

    private boolean addToLocalUrls(String url) {
        String listString = localSP.getString(GRN_DEMO_ADDRESS_LIST, "");
        if (!listString.contains(url)) {
            listString += url;
            if (!TextUtils.isEmpty(listString)) {
                listString += ",";
            }
            localSP.edit().putString(GRN_DEMO_ADDRESS_LIST, listString).apply();
            simpleAdapter.add(url);
            simpleAdapter.notifyDataSetChanged();
            return true;
        }
        return false;
    }

    private void gotoLocalConfigIfOk() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
            gotoLocalConfig();
        } else if (Build.VERSION.SDK_INT >= 23) {
            requestPermissions(new String[]{Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE}, 000);
        }
    }

    private void gotoLocalConfig() {
        File entryFile = new File("/sdcard/.__RN_Debug_URL.log");
        if (entryFile != null && entryFile.exists()) {
            String url = FileUtil.readFileAsString(entryFile);
            if (!GRNURL.isGRNURL(url)) {
                Toast.makeText(MainActivity.this, "GRN URL is illegal!", Toast.LENGTH_SHORT).show();
                return;
            }

            addToLocalUrls(url);
            startGRNBaseActivity(url.trim());
            entryFile.delete();
        }
    }

    private void requestSystemAlertWindow() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            startActivityForResult(new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:" + getPackageName())), 2);
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (grantResults[0] == android.content.pm.PackageManager.PERMISSION_GRANTED) {
            gotoLocalConfig();
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            Toast.makeText(this, "权限失败", Toast.LENGTH_SHORT).show();
        }
    }

    private void startGRNBaseActivity(String url) {
        if (!GRNURL.isGRNURL(url)) {
            Toast.makeText(MainActivity.this, "GRN URL is illegal!", Toast.LENGTH_SHORT).show();
            return;
        }
        GRNURL grnurl = new GRNURL(url);
        if (grnurl.getRnSourceType() != GRNURL.SourceType.Online) {
            PackageManager.installPackageForProduct(grnurl.getProductName());
        }
        Intent intent = new Intent(MainActivity.this, GRNBaseActivity.class);
        intent.putExtra(GRNBaseActivity.INTENT_COMPONENT_NAME, grnurl);
        startActivity(intent);
    }

}
