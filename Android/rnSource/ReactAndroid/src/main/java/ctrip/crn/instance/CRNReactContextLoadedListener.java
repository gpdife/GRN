package ctrip.grn.instance;

import com.facebook.react.ReactInstanceManager;

/**
 * Created by neo on 12/12/2017.
 */

public interface GRNReactContextLoadedListener {

    /**
     * instance加载完回调
     * @param reactInstanceManager reactInstanceManager
     */
    public void onReactContextLoaded(ReactInstanceManager reactInstanceManager);

}
