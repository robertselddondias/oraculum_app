import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Carrega as propriedades do arquivo key.properties
val signingProperties = Properties()
val signingPropertiesFile = project.rootProject.file("key.properties")
if (signingPropertiesFile.exists()) {
    signingProperties.load(FileInputStream(signingPropertiesFile))
} else {
    // É crucial que este arquivo exista para o build de release.
    // Se não existir, o build falhará com uma mensagem clara.
    println("ERRO: O arquivo key.properties não foi encontrado. Certifique-se de que ele está na pasta 'android/'.")
    // Você pode até lançar uma exceção para parar o build
    // throw GradleException("key.properties file not found!")
}

android {
    namespace = "com.selddon.oraculum"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.selddon.oraculum"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            // Tenta carregar os valores do key.properties
            storeFile = file(signingProperties.getProperty("storeFile") ?: "release-key.jks")
            storePassword = signingProperties.getProperty("storePassword")
            keyAlias = signingProperties.getProperty("keyAlias")
            keyPassword = signingProperties.getProperty("keyPassword")

            // Adicione uma verificação básica para depuração se as propriedades não forem carregadas
            if (storePassword == null || keyPassword == null || keyAlias == null) {
                println("AVISO: Credenciais de assinatura incompletas. Verifique o key.properties.")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }

    buildFeatures {
        buildConfig = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
