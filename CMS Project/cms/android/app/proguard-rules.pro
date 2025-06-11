# TensorFlow Lite rules
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Keep the GPU Delegate and related options
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**