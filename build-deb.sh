#!/bin/bash

# Define package name and version
PACKAGE_NAME="i3-browser"
PACKAGE_VERSION="1.0"

# Create necessary directories
mkdir -p ${PACKAGE_NAME}/DEBIAN
mkdir -p ${PACKAGE_NAME}/usr/local/bin
mkdir -p ${PACKAGE_NAME}/opt/${PACKAGE_NAME}

# Copy the main Python script
cp main.py ${PACKAGE_NAME}/opt/${PACKAGE_NAME}/

# Copy the control file
cat <<EOL > ${PACKAGE_NAME}/DEBIAN/control
Package: ${PACKAGE_NAME}
Version: ${PACKAGE_VERSION}
Section: web
Priority: optional
Architecture: all
Depends: python3, python3-pyqt5, python3-pyqt5.qtwebengine
Maintainer: Your Name <your.email@example.com>
Description: A simple web browser for i3 window manager
 A minimalist web browser for the i3 window manager, written in Python with PyQt5.
EOL

# Create the executable script
cat <<EOL > ${PACKAGE_NAME}/usr/local/bin/i3-browser
#!/bin/bash
python3 /opt/${PACKAGE_NAME}/main.py "\$@"
EOL
chmod +x ${PACKAGE_NAME}/usr/local/bin/i3-browser

# Build the package
dpkg-deb --build ${PACKAGE_NAME}

# Clean up
rm -rf ${PACKAGE_NAME}

echo "Package ${PACKAGE_NAME}_${PACKAGE_VERSION}.deb has been created."
