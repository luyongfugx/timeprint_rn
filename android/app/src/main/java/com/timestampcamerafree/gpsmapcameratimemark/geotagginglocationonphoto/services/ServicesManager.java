package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services;

import java.util.HashMap;
import java.util.Map;

/**
    service 管理类
 */
public final class ServicesManager {

    private static Map<Class<? extends IService>, Class<? extends IService>> serviceImplClazzMap = new HashMap<>();

    private static Map<Class<? extends IService>, IService> serviceImplMap = new HashMap();


    public static <T extends IService> T as(Class<T> serviceClazz) {
        T impl = (T) serviceImplMap.get(serviceClazz);
        if (impl == null) {
            Class<T> implClazz = (Class<T>) serviceImplClazzMap.get(serviceClazz);
            try {
                impl = implClazz.newInstance();
            } catch (IllegalAccessException | InstantiationException | NullPointerException e) {
                e.printStackTrace();
            }
            serviceImplMap.put(serviceClazz, impl);
        }
        return impl;
    }



    public static <T extends IService> void register(Class<T> service, Class<? extends T> serviceImpl) {
        serviceImplClazzMap.put(service, serviceImpl);
    }


    public static <T extends IService> void register(Class<T> service, T serviceImpl) {
        serviceImplMap.put(service, serviceImpl);
    }
}
