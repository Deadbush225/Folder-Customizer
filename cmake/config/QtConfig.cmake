# Qt6 configuration and detection
# Ensures Qt6 is found with proper versioning and configuration

find_package(Qt6 QUIET COMPONENTS Widgets Core)
message(STATUS "Using Qt version: ${Qt6Core_VERSION}")

qt_standard_project_setup()

message(STATUS "Qt6 configuration complete")
