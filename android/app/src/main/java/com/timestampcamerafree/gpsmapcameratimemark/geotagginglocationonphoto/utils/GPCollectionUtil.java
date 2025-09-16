package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils;

import java.util.Collection;
import java.util.Map;


public class GPCollectionUtil {

    public static boolean isEmpty(Collection collection) {
        return collection == null || collection.isEmpty();
    }

    public static <T> boolean isArrayEmpty(T... array) {
        return array == null || array.length <= 0;
    }

    public static boolean isEmpty(Map map) {
        return map == null || map.keySet() == null || map.keySet().isEmpty();
    }

    public static int size(Collection collection) {
        return collection == null ? 0 : collection.size();
    }
}
