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
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val configureNamespace: () -> Unit = {
        val android = extensions.findByName("android")
        if (android != null) {
            extensions.configure<com.android.build.gradle.BaseExtension> {
                if (namespace.isNullOrEmpty()) {
                    namespace = project.group.toString().takeIf { it.isNotEmpty() }
                        ?: "com.example.${project.name.replace("-", ".")}"
                }
            }
        }
    }

    if (project.state.executed) {
        configureNamespace()
    } else {
        afterEvaluate {
            configureNamespace()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

