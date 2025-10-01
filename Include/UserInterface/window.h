#ifndef WINDOW_H
#define WINDOW_H

#include <iostream>

#include <QtCore/QString>
#include <QtGui/QAction>
#include <QtWidgets/QApplication>
#include <QtWidgets/QCheckBox>
#include <QtWidgets/QComboBox>
#include <QtWidgets/QDockWidget>
#include <QtWidgets/QFileDialog>
#include <QtWidgets/QGroupBox>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QHeaderView>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMenuBar>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QTableWidget>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

#ifdef _WIN32
#include <windows.h>
#endif

#include "Core/registry.h"
#include "Customizer/folderCustomizer.h"
#include "Customizer/settings.h"
#include "Logger/logger.h"
#include "subclass.h"

class FolderCustomizerWindow : public QMainWindow {
   public:
    FolderCustomizerWindow();
    RegistryManipulator* registryManipulator = new RegistryManipulator();
    Settings* settings = new Settings();

    void applyStylesheet();

    void deleteSelectedItem();
    void setupToolBar();
    void clearAll();

    void apply();
    void reset();

   private:
    void setDarkTheme();

    eTableWidget* tableview;

    // QPushButton* install_key_act;
    // QPushButton* uninstall_key_btn;
    // QPushButton* check_updates_btn;
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