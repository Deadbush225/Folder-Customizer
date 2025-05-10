#ifndef WINDOW_H
#define WINDOW_H

#include <iostream>

#include <QtCore/QString>
#include <QtWidgets/QApplication>
#include <QtWidgets/QCheckBox>
#include <QtWidgets/QComboBox>
#include <QtWidgets/QGroupBox>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QListView>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

#include <windows.h>

#include "Core/registry.h"
#include "Customizer/folderCustomizer.h"
#include "Customizer/settings.h"
#include "Logger/logger.h"
#include "subclass.h"

class FolderCustomizerWindow : public QWidget {
   public:
    FolderCustomizerWindow();
    RegistryManipulator* registryManipulator = new RegistryManipulator();
    Settings* settings = new Settings();

    void hide_show_advanced_settings();  // LATER
    void deleteSelectedItem();
    void clearAll();

    void apply();
    void reset();

   private:
    void setDarkTheme();

    ListBoxwidget* listview;

    QPushButton* install_key_btn;
    QPushButton* uninstall_key_btn;
    QPushButton* check_updates_btn;
    QHSeparationLine* separator_horizontal;

    QComboBox* tone_comboBox;
    QComboBox* color_comboBox;

    QString* programPath;

    QGroupBox* yes_tag_chkbx;
    QGroupBox* yes_icon_chkbx;

    QLineEdit* line_edit;

    QCheckBox* resetIcon_chkbx;
    QCheckBox* resetTag_chkbx;
};

#endif