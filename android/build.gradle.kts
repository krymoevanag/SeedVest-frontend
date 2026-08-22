allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val sharedBuildRoot = newBuildDir.asFile.toPath().root?.toString()?.lowercase()
    val projectRoot = project.projectDir.toPath().root?.toString()?.lowercase()

    // Keep external Flutter plugins on their native drive to avoid Windows path
    // relativization errors when the app lives on a different drive.
    if (projectRoot == sharedBuildRoot) {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}