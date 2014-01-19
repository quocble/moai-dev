
# boost_system
#
include $(CLEAR_VARS)
LOCAL_MODULE := boost_system
LOCAL_SRC_FILES := boost/lib/libboost_system-gcc-mt-1_53.a
include $(PREBUILT_STATIC_LIBRARY)

# boost thread
#
include $(CLEAR_VARS)
LOCAL_MODULE := boost_thread
LOCAL_SRC_FILES := boost/lib/libboost_thread-gcc-mt-1_53.a
include $(PREBUILT_STATIC_LIBRARY)

# boost random
#
include $(CLEAR_VARS)
LOCAL_MODULE := boost_random
LOCAL_SRC_FILES := boost/lib/libboost_random-gcc-mt-1_53.a
include $(PREBUILT_STATIC_LIBRARY)