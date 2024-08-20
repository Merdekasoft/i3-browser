#!/bin/bash

# Define package name, version, and maintainer
PACKAGE_NAME="i3-browser"
PACKAGE_VERSION="1.0"
MAINTAINER="Your Name <your.email@example.com>"

# Create the directory structure for the package
mkdir -p ${PACKAGE_NAME}/DEBIAN
mkdir -p ${PACKAGE_NAME}/usr/local/bin
mkdir -p ${PACKAGE_NAME}/opt/${PACKAGE_NAME}

# Create the control file
cat <<EOL > ${PACKAGE_NAME}/DEBIAN/control
Package: ${PACKAGE_NAME}
Version: ${PACKAGE_VERSION}
Section: web
Priority: optional
Architecture: all
Depends: python3, python3-pyqt5, python3-pyqt5.qtwebengine
Maintainer: ${MAINTAINER}
Description: A simple web browser for i3 window manager
 A minimalist web browser for the i3 window manager, written in Python with PyQt5.
EOL

# Create the main Python script
cat <<'EOL' > ${PACKAGE_NAME}/opt/${PACKAGE_NAME}/main.py
#!/usr/bin/env python3

import sys
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QToolBar, QAction, QLineEdit, QWidget, QVBoxLayout, 
    QFileDialog, QProgressBar, QLabel, QListWidget, QListWidgetItem,
    QDockWidget, QShortcut
)
from PyQt5.QtGui import QKeySequence
from PyQt5.QtWebEngineWidgets import QWebEngineView, QWebEngineDownloadItem
from PyQt5.QtCore import Qt, QUrl

class DownloadItemWidget(QWidget):
    def __init__(self, file_name, parent=None):
        super().__init__(parent)
        self.progress_bar = QProgressBar()
        self.file_name_label = QLabel(file_name)

        layout = QVBoxLayout()
        layout.addWidget(self.file_name_label)
        layout.addWidget(self.progress_bar)
        self.setLayout(layout)

    def update_progress(self, bytes_received, bytes_total):
        if bytes_total > 0:
            progress = int((bytes_received / bytes_total) * 100)
            self.progress_bar.setValue(progress)

class Browser(QMainWindow):
    def __init__(self, initial_url=None):
        super().__init__()
        self.browser = QWebEngineView()

        # Set the initial URL
        if initial_url:
            if not initial_url.startswith('http://') and not initial_url.startswith('https://'):
                initial_url = 'https://www.google.com/search?q=' + initial_url
            self.browser.setUrl(QUrl(initial_url))
        else:
            self.browser.setUrl(QUrl("https://www.google.com"))

        # Connect download request signal to the handler
        self.browser.page().profile().downloadRequested.connect(self.handle_download)

        # Central Widget and Layout
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        layout = QVBoxLayout(central_widget)
        layout.addWidget(self.browser)

        # Toolbar at the bottom
        self.navbar = QToolBar()
        self.navbar.setMovable(False)  # Make the toolbar fixed
        layout.addWidget(self.navbar)

        # Back button
        back_btn = QAction('Back', self)
        back_btn.triggered.connect(self.browser.back)
        self.navbar.addAction(back_btn)

        # Forward button
        forward_btn = QAction('Forward', self)
        forward_btn.triggered.connect(self.browser.forward)
        self.navbar.addAction(forward_btn)

        # Reload button
        reload_btn = QAction('Reload', self)
        reload_btn.triggered.connect(self.browser.reload)
        self.navbar.addAction(reload_btn)

        # Home button
        home_btn = QAction('Home', self)
        home_btn.triggered.connect(self.navigate_home)
        self.navbar.addAction(home_btn)

        # URL bar
        self.url_bar = CustomQLineEdit(self)
        self.url_bar.returnPressed.connect(self.navigate_to_url)
        self.navbar.addWidget(self.url_bar)

        # Update URL bar when URL changes
        self.browser.urlChanged.connect(self.update_url)

        # Create download manager panel
        self.download_list_widget = QListWidget()
        self.download_manager = QDockWidget("Downloads", self)
        self.download_manager.setWidget(self.download_list_widget)
        self.addDockWidget(Qt.RightDockWidgetArea, self.download_manager)

        # Hide download manager initially
        self.download_manager.setVisible(False)

        # Add a shortcut to toggle the download manager
        self.shortcut = QShortcut(QKeySequence("Ctrl+J"), self)
        self.shortcut.activated.connect(self.toggle_download_manager)

    def navigate_home(self):
        self.browser.setUrl(QUrl("http://www.google.com"))

    def navigate_to_url(self, add_com=False):
        url = self.url_bar.text()

        # If Control key is held or add_com is True, add ".com" if not present
        if add_com:
            if not url.endswith('.com'):
                url += '.com'

        # If the input is a valid URL (contains a dot), assume it's a URL
        if '.' in url and not url.startswith('http'):
            url = 'http://' + url

        # If it's not a valid URL, treat it as a search term
        if not url.startswith('http'):
            url = 'https://www.google.com/search?q=' + url

        self.browser.setUrl(QUrl(url))

    def update_url(self, q):
        self.url_bar.setText(q.toString())

    def handle_download(self, download_item: QWebEngineDownloadItem):
        # Ask the user where to save the file
        save_path, _ = QFileDialog.getSaveFileName(self, "Save File", download_item.path())
        if save_path:
            download_item.setPath(save_path)
            download_item.accept()

            # Create a widget for the download item with filename
            file_name = download_item.path().split('/')[-1]
            download_widget = DownloadItemWidget(file_name)
            list_item = QListWidgetItem(self.download_list_widget)
            list_item.setSizeHint(download_widget.sizeHint())
            self.download_list_widget.addItem(list_item)
            self.download_list_widget.setItemWidget(list_item, download_widget)

            # Show the download manager panel
            self.download_manager.setVisible(True)

            # Connect the download progress to the widget
            download_item.downloadProgress.connect(download_widget.update_progress)

    def toggle_download_manager(self):
        # Toggle the visibility of the download manager
        self.download_manager.setVisible(not self.download_manager.isVisible())

class CustomQLineEdit(QLineEdit):
    def __init__(self, parent_browser):
        super().__init__()
        self.parent_browser = parent_browser

    def mousePressEvent(self, event):
        super().mousePressEvent(event)
        self.selectAll()

    def keyPressEvent(self, event):
        # Capture Ctrl+Enter and trigger the navigate_to_url with add_com=True
        if event.key() == Qt.Key_Return and event.modifiers() == Qt.ControlModifier:
            self.parent_browser.navigate_to_url(add_com=True)
        else:
            super().keyPressEvent(event)

if __name__ == '__main__':
    app = QApplication(sys.argv)
    QApplication.setApplicationName('i3 Browser')

    # Handle command-line arguments
    initial_url = None
    if len(sys.argv) > 1:
        initial_url = sys.argv[1]
        if not initial_url.startswith('http://') and not initial_url.startswith('https://'):
            initial_url = 'https://www.google.com/search?q=' + initial_url

    window = Browser(initial_url)
    window.showMaximized()
    app.exec_()
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
