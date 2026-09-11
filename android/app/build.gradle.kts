import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Keystore de release: nunca versionado (ver docs/2-SECURITY_REPORT.md, SEC-002).
// Sem android/key.properties, qualquer task de release falha explicitamente
// (ver checagem via gradle.taskGraph.whenReady abaixo) — builds de debug/CI
// continuam funcionando sem a keystore de produção.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasKeystoreProperties = keystorePropertiesFile.exists()
if (hasKeystoreProperties) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// SEC-002: falha o build antes de compilar/assinar qualquer task de release
// sem a keystore de produção, em vez de cair silenciosamente para a
// assinatura de debug. Usa o grafo de tasks resolvido (não a fase de
// configuração) para não afetar `flutter build apk --debug`/`flutter test`.
gradle.taskGraph.whenReady {
    val buildingRelease = allTasks.any { it.name.contains("Release") }
    if (buildingRelease && !hasKeystoreProperties) {
        throw GradleException(
            "Build de release sem android/key.properties. Crie o arquivo a partir de " +
                "android/key.properties.example com a keystore de produção antes de gerar " +
                "um build de release (ver docs/2-SECURITY_REPORT.md, SEC-002)."
        )
    }
}

android {
    namespace = "br.com.dcbsys.beatspan"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        manifestPlaceholders += mapOf(
            "redirectSchemeName" to "spotify-sdk",
            "redirectHostName" to "auth"
        )
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "br.com.dcbsys.beatspan"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasKeystoreProperties) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Usa a keystore de produção quando android/key.properties existe
            // (ver android/key.properties.example). O fallback para debug abaixo
            // só é avaliado na fase de configuração (AGP configura todas as build
            // types); a task graph check acima já aborta o build antes de gerar
            // qualquer artefato de release assinado com a chave de debug.
            signingConfig = if (hasKeystoreProperties) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
