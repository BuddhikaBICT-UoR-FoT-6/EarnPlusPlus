allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Keep Android subproject outputs under Flutter's root build/ directory.
// Flutter tooling expects APK artifacts in ../../build/app/outputs/flutter-apk.
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
