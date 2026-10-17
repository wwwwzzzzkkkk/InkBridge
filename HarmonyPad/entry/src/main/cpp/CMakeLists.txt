cmake_minimum_required(VERSION 3.5.0)
project(InkBridgeScreenMirror)

add_library(screenmirror SHARED screen_mirror.cpp)
target_link_libraries(screenmirror PUBLIC
  libace_napi.z.so
  libhilog_ndk.z.so
  libnative_avscreen_capture.so
  libnative_media_codecbase.so
  libnative_media_core.so
  libnative_media_venc.so
  libnative_window.so
)
