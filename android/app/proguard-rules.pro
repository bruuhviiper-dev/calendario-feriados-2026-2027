# flutter_local_notifications usa Gson via reflexao para (de)serializar os
# detalhes agendados. Sem estas regras o R8 remove/renomeia as classes e a
# notificacao programada QUEBRA (some apos reboot / nao dispara).
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
# Mantem os campos anotados com @SerializedName (nomes originais no JSON).
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Google Mobile Ads / Play Core (evita avisos de classes ausentes no R8).
-dontwarn com.google.android.play.core.**
