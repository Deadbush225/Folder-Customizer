#include "UserInterface/window.h"
#include <QtCore/QCoreApplication>
#include <QtCore/QFileInfo>
#include <QtCore/QProcess>
#include <QtWidgets/QMessageBox>

QStringList* stdToQStringList(std::vector<std::string> stdStringList) {
    QStringList* tones = new QStringList();
    for (std::string tone : stdStringList) {
        tones->append(QString::fromStdString(tone));
    }
    return tones;
}

FolderCustomizerWindow::FolderCustomizerWindow() {
    this->setWindowIcon(QIcon(":/icons/Folder Customizer.ico"));

    setDarkTheme();
    // Logger* log = new Logger();
    // log->write(QString("Test message"), LOGGER::CHRONOLOGY::AFT,
    //            LOGGER::STATUS::WARN, LOGGER::PRIORITY::MID);

    ////////// DEBUG

    this->programPath = new QString("C:\\Program Files\\Folder Customizer");

    // + DND Layout
    this->tableview = new eTableWidget();
    this->tableview->setColumnCount(2);
    this->tableview->horizontalHeader()->setVisible(false);

    // Make the left column thin and unstretchable, stretch the right column
    this->tableview->horizontalHeader()->setSectionResizeMode(
        1, QHeaderView::Fixed);
    this->tableview->horizontalHeader()->setSectionResizeMode(
        0, QHeaderView::Stretch);
    this->tableview->setColumnWidth(1, 32);  // Thin for checkboxes
    // this->tableview->addItem("C:\\Users\\Eliaz\\Desktop\\Test");

    QHBoxLayout* buttonLayout = new QHBoxLayout();

    auto btn_Del = new QPushButton(QString("Delete"));
    QObject::connect(btn_Del, &QPushButton::clicked, this,
                     &FolderCustomizerWindow::deleteSelectedItem);
    // buttonLayout->addWidget(btn_Del);

    auto btn_ClearAll = new QPushButton("Clear All");
    QObject::connect(btn_ClearAll, &QPushButton::clicked, this,
                     &FolderCustomizerWindow::clearAll);
    buttonLayout->addWidget(btn_ClearAll);

    auto btn_Browse = new QPushButton("Browse");
    QObject::connect(btn_Browse, &QPushButton::clicked, this, [this]() {
        QString dir = QFileDialog::getExistingDirectory(this, "Select Folder");
        if (!dir.isEmpty()) {
            // this->tableview->addItem(dir);
            this->tableview->addItem(dir);
        }
    });
    buttonLayout->addWidget(btn_Browse);
    auto dnd_layout = new QVBoxLayout();
    dnd_layout->addLayout(buttonLayout);
    dnd_layout->addWidget(this->tableview);

    // + Customization Layout
    auto settings_menu = this->menuBar()->addMenu("&Settings");

    auto install_key_act = new QAction("Add to context menu", this);
    QObject::connect(install_key_act, &QAction::triggered, this,
                     [this]() { registryManipulator->installRegistry(); });

    auto uninstall_key_act = new QAction("Remove from context menu", this);
    QObject::connect(uninstall_key_act, &QAction::triggered, this,
                     [this]() { registryManipulator->uninstallRegistry(); });

#ifdef Q_OS_WIN
    settings_menu->addAction(uninstall_key_act);
    settings_menu->addAction(install_key_act);
#endif

    auto help_menu = this->menuBar()->addMenu("&Help");
    auto check_updates_act = new QAction("Check Updates", this);
    QObject::connect(check_updates_act, &QAction::triggered, this, [this]() {
        QString updaterPath =
            QCoreApplication::applicationDirPath() + "/eUpdater";
#ifdef Q_OS_WIN
        updaterPath += ".exe";
#endif
        if (QFileInfo::exists(updaterPath)) {
            // eUpdater is expected to be built with the manifest URL
            // and installer template baked in, so invoke it without CLI
            // args.
            if (!QProcess::startDetached(updaterPath)) {
                QMessageBox::warning(this, "Update Check",
                                     "Failed to start the Updater.");
            }
        } else {
            QMessageBox::information(
                this, "Updater Not Found",
                "Updater was not found next to the application.\n"
                "Please download the latest release from GitHub.");
        }
    });
    help_menu->addAction(check_updates_act);

    auto reset_stylesheets_act = new QAction("Reset Stylesheet", this);
    QObject::connect(reset_stylesheets_act, &QAction::triggered, this,
                     &FolderCustomizerWindow::applyStylesheet);
    settings_menu->addAction(reset_stylesheets_act);

    separator_horizontal = new QHSeparationLine();
    separator_horizontal->setHidden(true);

    // + -> Tone combo box
    this->yes_icon_chkbx = new ModGroupBox("Add an Icon?");
    this->yes_icon_chkbx->setChecked(false);

    auto tone_comboBox_Layout = new QHBoxLayout();
    auto tone_comboBox_label = new QLabel("Tone: ");

    this->tone_comboBox = new QComboBox();

    tone_comboBox->addItems(*stdToQStringList(settings->tones));
    tone_comboBox->setCurrentIndex(1);

    tone_comboBox_Layout->addWidget(tone_comboBox_label);
    tone_comboBox_Layout->addWidget(tone_comboBox);

    // + -> Color combo box
    auto color_comboBox_Layout = new QHBoxLayout();
    auto color_comboBox_label = new QLabel("Color: ");

    this->color_comboBox = new QComboBox();
    color_comboBox->addItems(*stdToQStringList(settings->colors));
    color_comboBox->setCurrentIndex(0);

    color_comboBox_Layout->addWidget(color_comboBox_label);
    color_comboBox_Layout->addWidget(color_comboBox);

    // + COMBO BOX Layout
    auto combo_layout = new QHBoxLayout();
    combo_layout->addLayout(tone_comboBox_Layout);
    combo_layout->addLayout(color_comboBox_Layout);

    this->yes_icon_chkbx->setLayout(combo_layout);

    // + no label checkbox
    // auto no_label_layout = QHBoxLayout()
    this->yes_tag_chkbx = new ModGroupBox("Add a Tag?");

    // + line edit layout
    auto line_edit_layout = new QHBoxLayout();
    auto line_edit_label = new QLabel("Custom Tag");
    this->line_edit = new QLineEdit();
    this->line_edit->setPlaceholderText("Acads, Hobby, Database...");

    line_edit_layout->addWidget(line_edit_label);
    line_edit_layout->addWidget(this->line_edit);
    this->yes_tag_chkbx->setLayout(line_edit_layout);

    // + apply button
    auto apply_button = new QPushButton("Apply now");
    QObject::connect(apply_button, &QPushButton::clicked, this,
                     &FolderCustomizerWindow::apply);

    // + RESET CHECKBOX
    auto reset_grpbx = new QGroupBox("What to Reset?");

    auto resetCheckBoxLayout = new QVBoxLayout();
    reset_grpbx->setLayout(resetCheckBoxLayout);

    resetIcon_chkbx = new QCheckBox("Reset Icon");
    resetTag_chkbx = new QCheckBox("Reset Tag");

    resetCheckBoxLayout->addWidget(resetIcon_chkbx);
    resetCheckBoxLayout->addWidget(resetTag_chkbx);

    // + reset button
    auto reset_button = new QPushButton("Reset now");
    QObject::connect(reset_button, &QPushButton::clicked, this,
                     &FolderCustomizerWindow::reset);

    // + CUSTOMIZATION Layout
    QDockWidget* customizationDock = new QDockWidget("Customize");
    QWidget* widget = new QWidget(customizationDock);

    auto customization_layout = new QVBoxLayout();

    customization_layout->addWidget(this->yes_icon_chkbx);
    // customization_layout->addLayout(combo_layout);  // referred 2 times
    customization_layout->addWidget(this->yes_tag_chkbx);
    // customization_layout->addLayout(line_edit_layout);  // referred 2
    // times
    customization_layout->addWidget(apply_button);

    customization_layout->addStretch();

    customization_layout->addWidget(new QHSeparationLine());
    customization_layout->addWidget(reset_grpbx);
    customization_layout->addWidget(reset_button);
    widget->setLayout(customization_layout);
    customizationDock->setWidget(widget);
    customizationDock->setFeatures(QDockWidget::DockWidgetMovable |
                                   QDockWidget::DockWidgetFloatable);

    this->addDockWidget(Qt::DockWidgetArea::RightDockWidgetArea,
                        customizationDock);

    // customization_layout->addStretch();

    // + MAIN Layout
    QHBoxLayout* mainLayout = new QHBoxLayout();
    mainLayout->addLayout(dnd_layout, 7);

    QWidget* centralWidget = new QWidget();
    centralWidget->setLayout(mainLayout);

    this->setCentralWidget(centralWidget);
}

void FolderCustomizerWindow::setupToolBar() {}

void FolderCustomizerWindow::deleteSelectedItem() {
    QModelIndexList selected =
        this->tableview->selectionModel()->selectedIndexes();

    QList<int> indexes = {};

    for (QModelIndex index : selected) {
        indexes.append(index.row());
        // index.row();
    }

    std::sort(indexes.begin(), indexes.end(),
              [](const int a, const int b) -> bool { return a > b; });

    for (int index : indexes) {
        this->tableview->removeItem(index);
    }
}

void FolderCustomizerWindow::clearAll() {
    this->tableview->clear();
}

void FolderCustomizerWindow::apply() {
    QString tone = this->tone_comboBox->currentText();
    QString color = this->color_comboBox->currentText();
    QList<QString> folders = this->tableview->getAllItems();

    // QString icon_path = *(this->programPath) + tone + color + ".ico";

    QString defaultTag = "";
    if (this->yes_icon_chkbx->isChecked())
        defaultTag = tone + " " + color;

    QString customTag = this->line_edit->text().simplified();

    // qDebug() << this->no_label_chkbx->isChecked();

    QString tag =
        customTag.isEmpty()
            ? (defaultTag.simplified().isEmpty() ? "Default Tag" : defaultTag)
            : customTag;
    // this->folderColorizeTagger();
    qDebug() << "tag: " << tag;
    qDebug() << "folders: " << folders;

    for (QString folder : folders) {
        qDebug() << "folderColorizeTagger(" + folder + ", " + tone + ", " +
                        color + "," + tag + ")";
        FolderCustomizer::colorizeTag(folder, tone, color, tag);
    }
}

void FolderCustomizerWindow::reset() {
    bool resetIcon = resetIcon_chkbx->isChecked();
    bool resetTag = resetTag_chkbx->isChecked();
    QList<QString> folders = this->tableview->getAllItems();

    for (QString folder : folders) {
        FolderCustomizer::reset(folder, resetIcon, resetTag);
    }
}

void FolderCustomizerWindow::applyStylesheet() {
    QFile styleFile("style.qss");
    qDebug() << "Style file full path:"
             << QFileInfo(styleFile).absoluteFilePath();
    if (styleFile.open(QFile::ReadOnly | QFile::Text)) {
        QString styleSheet = styleFile.readAll();
        qApp->setStyleSheet(styleSheet);
        styleFile.close();
    }
}

void FolderCustomizerWindow::setDarkTheme() {
    QApplication::setStyle("Fusion");

    QPalette* dark_palette = new QPalette();
    dark_palette->setColor(QPalette::Window, QColor(53, 53, 53));
    dark_palette->setColor(QPalette::WindowText, Qt::white);
    dark_palette->setColor(QPalette::Base, QColor(35, 35, 35));
    dark_palette->setColor(QPalette::AlternateBase, QColor(53, 53, 53));
    dark_palette->setColor(QPalette::ToolTipBase, QColor(25, 25, 25));
    dark_palette->setColor(QPalette::ToolTipText, Qt::white);
    dark_palette->setColor(QPalette::Text, Qt::white);
    dark_palette->setColor(QPalette::Button, QColor(53, 53, 53));
    dark_palette->setColor(QPalette::ButtonText, Qt::white);
    dark_palette->setColor(QPalette::BrightText, Qt::red);
    dark_palette->setColor(QPalette::Link, QColor(42, 130, 218));
    dark_palette->setColor(QPalette::Highlight, QColor(42, 130, 218));
    dark_palette->setColor(QPalette::HighlightedText, QColor(35, 35, 35));
    dark_palette->setColor(QPalette::Active, QPalette::Button,
                           QColor(53, 53, 53));
    dark_palette->setColor(QPalette::Disabled, QPalette::ButtonText,
                           Qt::darkGray);
    dark_palette->setColor(QPalette::Disabled, QPalette::WindowText,
                           Qt::darkGray);
    dark_palette->setColor(QPalette::Disabled, QPalette::Text, Qt::darkGray);
    dark_palette->setColor(QPalette::Disabled, QPalette::Light,
                           QColor(53, 53, 53));
    QApplication::setPalette(*dark_palette);

    qApp->setStyleSheet(R"(
            QGroupBox { 
    border: 1px solid #2f2f2f;
    border-radius: 3px;
    margin-top: 0.6em; 
    padding: 0.3em;
}

QGroupBox::title {
    subcontrol-origin: margin;
    margin-left: 0em;
}

QFrame[frameShape="4"] { /* QFrame::HLine */
    border: none;
    border-top: 1px solid #2f2f2f;
    background: #2f2f2f;
    margin: 0.5em 0;
})");
}