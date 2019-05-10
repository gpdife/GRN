package ctrip.grn.instance;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.TimeZone;

/**
 * Created by dev on 2018/8/16.
 */

public class GRNPageInfo {

    private static int guid = 0;

    public String grnPageID;
    public String grnPageName;

    public GRNPageInfo() {
        this.grnPageID = generateGRNPageID();
    }

    public static GRNPageInfo newGRNPageInfo(String grnPageName) {
        GRNPageInfo grnPageInfo = new GRNPageInfo();
        grnPageInfo.grnPageName = grnPageName;
        return grnPageInfo;
    }

    private static String generateGRNPageID() {
        Calendar calendar = Calendar.getInstance();
        String ret = "";
        if (calendar != null) {
            TimeZone timeZone  = calendar.getTimeZone();
            if (timeZone == null) {
                timeZone = TimeZone.getTimeZone("Asia/Shanghai");
            }
            SimpleDateFormat dateFormat = new SimpleDateFormat("yyyyMMddHHmmss.SSS");//yyyy-MM-dd HH:mm:ss.SSS
            dateFormat.setTimeZone(timeZone);
            ret = (dateFormat).format(calendar.getTime());
        }
        if (ret == null || ret.length() == 0) {
            ret = System.currentTimeMillis()+"";
        }
        return ret + "_" + (++guid);
    }


}
