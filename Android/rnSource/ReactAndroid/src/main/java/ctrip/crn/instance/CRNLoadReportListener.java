package ctrip.grn.instance;

import com.facebook.react.ReactInstanceManager;

/**
  * @author Leone
  * @date 8/8/16
  */
public interface GRNLoadReportListener {

    /**
     * instance加载完成回调
     * @param mng mng
     * @param time time
     */
    void onLoadComponentTime(ReactInstanceManager mng, long time);

}
