# Spotify App Remote SDK references Jackson databind classes and
# internal annotation classes that are not present at compile/runtime
# on Android but are only used for optional (non-Android) serialization
# paths. Safe to suppress since they are never exercised on this platform.
-dontwarn com.fasterxml.jackson.databind.deser.std.StdDeserializer
-dontwarn com.fasterxml.jackson.databind.ser.std.StdSerializer
-dontwarn com.spotify.base.annotations.NotNull

-keep class com.spotify.** { *; }
-dontwarn com.spotify.**
