# Spotify App Remote SDK usa Jackson internamente via reflection para
# (de)serializar seus modelos (ImageUri, PlayerState, etc). O R8 não
# consegue ver essas referências estaticamente e remove as classes,
# quebrando o SDK em runtime. Mantemos tudo do pacote do SDK e do Jackson.
-keep class com.spotify.** { *; }
-keep class com.fasterxml.jackson.** { *; }
-dontwarn com.spotify.**
-dontwarn com.fasterxml.jackson.**
