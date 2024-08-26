#!/usr/bin/env python3

import sys
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QToolBar, QAction, QLineEdit, QWidget, QVBoxLayout, 
    QFileDialog, QProgressBar, QLabel, QListWidget, QListWidgetItem,
    QDockWidget, QShortcut
)
from PyQt5.QtGui import QKeySequence, QIcon
from PyQt5.QtWebEngineWidgets import QWebEngineView, QWebEngineDownloadItem, QWebEnginePage
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
        back_btn = QAction('', self)
        back_btn.triggered.connect(self.browser.back)
        self.navbar.addAction(back_btn)

        # Forward button
        forward_btn = QAction('', self)
        forward_btn.triggered.connect(self.browser.forward)
        self.navbar.addAction(forward_btn)

        # Reload button
        reload_btn = QAction('', self)
        reload_btn.triggered.connect(self.browser.reload)
        self.navbar.addAction(reload_btn)

        # Home button
        home_btn = QAction('', self)
        home_btn.triggered.connect(self.navigate_home)
        self.navbar.addAction(home_btn)

        # URL bar
        self.url_bar = CustomQLineEdit(self)
        self.url_bar.returnPressed.connect(self.navigate_to_url)
        self.navbar.addWidget(self.url_bar)

        # Add Toggle Download Manager button
        toggle_download_btn = QAction(QIcon(), '', self)
        toggle_download_btn.triggered.connect(self.toggle_download_manager)
        self.navbar.addAction(toggle_download_btn)

        # Add Open File button
        open_file_btn = QAction('', self)
        open_file_btn.setShortcut(QKeySequence("Ctrl+O"))
        open_file_btn.triggered.connect(self.open_html_file)
        self.navbar.addAction(open_file_btn)

        # Add Save Page button
        save_page_btn = QAction('', self)
        save_page_btn.setShortcut(QKeySequence("Ctrl+S"))
        save_page_btn.triggered.connect(self.save_page)
        self.navbar.addAction(save_page_btn)

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

    def open_html_file(self):
        # Open a file dialog to select an HTML file
        file_path, _ = QFileDialog.getOpenFileName(self, "Open HTML File", "", "HTML Files (*.html *.htm)")
        if file_path:
            self.browser.setUrl(QUrl.fromLocalFile(file_path))

    def save_page(self):
        # Open a file dialog to select where to save the HTML file
        file_path, _ = QFileDialog.getSaveFileName(self, "Save HTML File", "", "HTML Files (*.html)")
        if file_path:
            # Ensure the file has an .html extension
            if not file_path.lower().endswith('.html'):
                file_path += '.html'
            
            # Get the page source and save it
            self.browser.page().toHtml(lambda html: self.save_html_to_file(file_path, html))

    def save_html_to_file(self, file_path, html):
        try:
            with open(file_path, 'w', encoding='utf-8') as file:
                file.write(html)
            print(f"Page saved to {file_path}")
        except Exception as e:
            print(f"Error saving page: {e}")

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
