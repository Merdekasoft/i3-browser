#!/bin/bash

# Define package name and version
PACKAGE_NAME="i3-browser"
PACKAGE_VERSION="1.0"

# Create necessary directories
mkdir -p ${PACKAGE_NAME}/DEBIAN
mkdir -p ${PACKAGE_NAME}/usr/local/bin
mkdir -p ${PACKAGE_NAME}/opt/${PACKAGE_NAME}
mkdir -p ${PACKAGE_NAME}/usr/share/applications

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
Maintainer: Admin <merdekasoft@gmail.com>
Description: A simple web browser for the i3 window manager
 A minimalist web browser for the i3 window manager, written in Python with PyQt5.
EOL

# Create the executable script
cat <<EOL > ${PACKAGE_NAME}/usr/local/bin/i3-browser
#!/bin/bash
python3 /opt/${PACKAGE_NAME}/main.py "\$@"
EOL
chmod +x ${PACKAGE_NAME}/usr/local/bin/i3-browser

# Create a desktop entry for the application
cat <<EOL > ${PACKAGE_NAME}/usr/share/applications/i3-browser.desktop
[Desktop Entry]
Name=I3 Browser
Comment=A simple web browser for the i3 window manager
Exec=i3-browser
Icon=web-browser
Terminal=false
Type=Application
Categories=Network;WebBrowser;
EOL

# Create post-installation script to set i3-browser as the default web browser
cat <<EOL > ${PACKAGE_NAME}/DEBIAN/postinst
#!/bin/bash
# Set i3-browser as the default web browser
xdg-settings set default-web-browser i3-browser.desktop
update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/local/bin/i3-browser 100
update-alternatives --set x-www-browser /usr/local/bin/i3-browser
update-alternatives --install /usr/bin/gnome-www-browser gnome-www-browser /usr/local/bin/i3-browser 100
update-alternatives --set gnome-www-browser /usr/local/bin/i3-browser
EOL
chmod +x ${PACKAGE_NAME}/DEBIAN/postinst

# Build the package
dpkg-deb --build ${PACKAGE_NAME}

# Clean up
rm -rf ${PACKAGE_NAME}

echo "Package ${PACKAGE_NAME}_${PACKAGE_VERSION}.deb has been created."
