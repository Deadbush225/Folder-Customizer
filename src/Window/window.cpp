#include "../../Include/Window/window.h"
#include <string>

FolderCustomizerWindow::FolderCustomizerWindow() {
    // Logger* log = new Logger();
    // log->write(QString("Test message"), LOGGER::CHRONOLOGY::AFT,
    //            LOGGER::STATUS::WARN, LOGGER::PRIORITY::MID);

    ////////// DEBUG

    this->programPath = new QString("C:\\Program Files\\Folder Customizer");

    // + DND Layout
    this->listview = new ListBoxwidget();
    // this->listview->addItem("C:\\Users\\Eliaz\\Desktop\\Test");

    QHBoxLayout* buttonLayout = new QHBoxLayout();

    auto btn_Del = new QPushButton(QString("Delete"));
    QObject::connect(btn_Del, QPushButton::clicked, this, &deleteSelectedItem);
    buttonLayout->addWidget(btn_Del);

    auto btn_ClearAll = new QPushButton("Clear All");
    QObject::connect(btn_ClearAll, QPushButton::clicked, this, &clearAll);
    buttonLayout->addWidget(btn_ClearAll);

    auto dnd_layout = new QVBoxLayout();
    dnd_layout->addLayout(buttonLayout);
    dnd_layout->addWidget(this->listview);

    // + Customization Layout

    auto show_more = new QPushButton("Show Advanced Settings");
    QObject::connect(show_more, QPushButton::clicked, this,
                     &hide_show_advanced_settings);

    install_key_btn = new QPushButton("Add to context menu");
    QObject::connect(install_key_btn, QPushButton::clicked, this,
                     &installRegistry);
    install_key_btn->setHidden(true);

    uninstall_key_btn = new QPushButton("Remove from context menu");
    // QObject::connect(uninstall_key_btn, QPushButton::clicked, this, )
    uninstall_key_btn->setHidden(true);

    separator_horizontal = new QHSeparationLine();
    separator_horizontal->setHidden(true);

    // + -> Tone combo box
    this->yes_icon_chkbx = new ModGroupBox("Add an Icon?");
    this->yes_icon_chkbx->setChecked(false);

    auto tone_comboBox_Layout = new QHBoxLayout();
    auto tone_comboBox_label = new QLabel("Tone: ");

    this->tone_comboBox = new QComboBox();
    tone_comboBox->addItems(tones);
    tone_comboBox->setCurrentIndex(1);

    tone_comboBox_Layout->addWidget(tone_comboBox_label);
    tone_comboBox_Layout->addWidget(tone_comboBox);

    // + -> Color combo box
    auto color_comboBox_Layout = new QHBoxLayout();
    auto color_comboBox_label = new QLabel("Color: ");

    this->color_comboBox = new QComboBox();
    color_comboBox->addItems(colors);
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

    line_edit_layout->addWidget(line_edit_label);
    line_edit_layout->addWidget(this->line_edit);
    this->yes_tag_chkbx->setLayout(line_edit_layout);

    // + RESET CHECKBOX
    auto resetCheckBoxLayout = new QVBoxLayout();

    resetIcon_chkbx = new QCheckBox("Default Icon");
    resetTag_chkbx = new QCheckBox("Default Tag");

    resetCheckBoxLayout->addWidget(resetIcon_chkbx);
    resetCheckBoxLayout->addWidget(resetTag_chkbx);

    // + apply button
    auto apply_button = new QPushButton("Apply");
    QObject::connect(apply_button, QPushButton::clicked, this, &apply);

    // + reset button
    auto reset_button = new QPushButton("Reset");
    QObject::connect(reset_button, QPushButton::clicked, this, &reset);

    // + CUSTOMIZATION Layout
    auto customization_layout = new QVBoxLayout();
    customization_layout->addWidget(show_more);
    customization_layout->addWidget(install_key_btn);
    customization_layout->addWidget(uninstall_key_btn);
    customization_layout->addWidget(new QHSeparationLine());

    customization_layout->addWidget(this->yes_icon_chkbx);
    // customization_layout->addLayout(combo_layout);  // referred 2 times
    customization_layout->addWidget(this->yes_tag_chkbx);
    // customization_layout->addLayout(line_edit_layout);  // referred 2 times
    customization_layout->addWidget(apply_button);

    customization_layout->addStretch();

    customization_layout->addWidget(new QHSeparationLine());
    customization_layout->addLayout(resetCheckBoxLayout);
    customization_layout->addWidget(reset_button);

    // customization_layout->addStretch();

    // + MAIN Layout
    QHBoxLayout* mainLayout = new QHBoxLayout();
    mainLayout->addLayout(dnd_layout, 7);
    mainLayout->addLayout(customization_layout);

    this->setLayout(mainLayout);
}

void FolderCustomizerWindow::deleteSelectedItem() {
    QModelIndexList selected = this->listview->selectedIndexes();

    QList<int> indexes = {};

    for (QModelIndex index : selected) {
        indexes.append(index.row());
        // index.row();
    }

    std::sort(indexes.begin(), indexes.end(),
              [](const int a, const int b) -> bool { return a > b; });

    for (int index : indexes) {
        this->listview->takeItem(index);
    }
}

void FolderCustomizerWindow::clearAll() {
    this->listview->clear();
}

void FolderCustomizerWindow::hide_show_advanced_settings() {
    this->install_key_btn->setHidden(!this->install_key_btn->isHidden());
    this->uninstall_key_btn->setHidden(!this->uninstall_key_btn->isHidden());
    // this->separator_horizontal->setHidden(
    //     !this->separator_horizontal->isHidden());
}

void FolderCustomizerWindow::apply() {
    QString tone = this->tone_comboBox->currentText();
    QString color = this->color_comboBox->currentText();
    QList<QString> folders = this->listview->getAllItems();

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
        folderColorizeTagger(folder, tone, color, tag);
    }
}

void FolderCustomizerWindow::reset() {
    bool resetIcon = resetIcon_chkbx->isChecked();
    bool resetTag = resetTag_chkbx->isChecked();
    QList<QString> folders = this->listview->getAllItems();

    for (QString folder : folders) {
        DesktopIniManipulator* desktopManip = new DesktopIniManipulator(folder);

        if (resetIcon) {
            qDebug() << "Reseting icon";
            desktopManip->removeSection(".ShellClassInfo");
        }

        if (resetTag) {
            qDebug() << "Reseting tag";
            desktopManip->removeSection(
                "{F29F85E0-4FF9-1068-AB91-08002B27B3D9}");
        }
    }
}

void FolderCustomizerWindow::folderColorizeTagger(QString folderPath,
                                                  QString tone,
                                                  QString color,
                                                  QString tag) {
    DesktopIniManipulator* desktopManip = new DesktopIniManipulator(folderPath);

    // if (!(tag.isNull() || tag.isEmpty())) {
    // qDebug() << "tag is empty";
    if (this->yes_tag_chkbx->isChecked()) {
        qDebug() << "Tagging Folder";
        desktopManip->tagFolder(folderPath, tag);
    }
    // }
    if (this->yes_icon_chkbx->isChecked()) {
        qDebug() << "Changing Icon";
        changeIcon(folderPath, tone, color);
    }

    delete desktopManip;
}

void FolderCustomizerWindow::createRegistryKey(HKEY hKeyRoot,
                                               LPCSTR subKey,
                                               LPCSTR valueName,
                                               LPCSTR value) {
    HKEY hKey;
    LONG result =
        RegCreateKeyExA(hKeyRoot, subKey, 0, NULL, REG_OPTION_NON_VOLATILE,
                        KEY_WRITE, NULL, &hKey, NULL);
    if (result == ERROR_SUCCESS) {
        RegSetValueExA(hKey, valueName, 0, REG_SZ, (const BYTE*)value,
                       strlen(value) + 1);
        RegCloseKey(hKey);
    } else {
        std::cerr << "Error creating registry key: " << result << std::endl;
    }
}

void FolderCustomizerWindow::installRegistry() {
    // Setup context menu item for click on right panel
    char rootMenu[] =
        R"(Software\Classes\directory\Background\shell\Folder Customizer)";

    // icon path
    createRegistryKey(
        HKEY_CURRENT_USER, rootMenu, "icon",
        R"("C:\Program Files\Folder Customizer\Icons\Folder Customizer.ico")");
    // set up to have submenu
    createRegistryKey(HKEY_CURRENT_USER, rootMenu, "SubCommands", "");

    // root name
    createRegistryKey(HKEY_CURRENT_USER, rootMenu, "MUIVerb",
                      "Folder Customizer");

    // command
    createRegistryKey(
        HKEY_CURRENT_USER, strcat(rootMenu, R"(\command)"), "",
        R"("C:\Program Files\Folder Customizer\Folder Customizer.exe" "%V")");

    for (QString tone : this->tones) {
        QString toneKeyPath =
            QString(strcat(rootMenu, R"(\shell\%1)")).arg(tone);
        createRegistryKey(HKEY_CURRENT_USER, toneKeyPath.toStdString().c_str(),
                          "", "");
        createRegistryKey(HKEY_CURRENT_USER, toneKeyPath.toStdString().c_str(),
                          "SubCommands", "");

        for (QString color : this->colors) {
            QString colorKeyPath =
                QString(strcat(rootMenu, R"(\shell\%1\shell\%2)"))
                    .arg(tone)
                    .arg(color);
            createRegistryKey(HKEY_CURRENT_USER,
                              colorKeyPath.toStdString().c_str(), "", "");
        }
    }

    // Setup context menu item for click on folders tree item
    createRegistryKey(
        HKEY_CURRENT_USER,
        R"(Software\Classes\directory\shell\Folder Customizer\command)", "",
        R"("C:\Program Files\Folder Customizer\Folder Customizer.exe" "%1")");
    createRegistryKey(
        HKEY_CURRENT_USER,
        R"(Software\Classes\directory\shell\Folder Customizer)", "icon",
        R"("C:\Program Files\Folder Customizer\Icons\Folder Customizer.ico")");
}

void FolderCustomizerWindow::uninstallRegistry() {}