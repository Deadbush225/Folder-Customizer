#ifndef WINDOW_H
#define WINDOW_H

#include <iostream>

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

#include "../Customizer/icon_refresher.h"
#include "../Customizer/tagger.h"
#include "../Logger/logger.h"
#include "subclass.h"

class FolderCustomizerWindow : public QWidget {
   public:
    QList<QString> colors = {"Red",    "Brown", "Orange", "Lemon",
                             "Green",  "Azure", "Blue",   "Pink",
                             "Violet", "White", "Gray",   "Black"};
    QList<QString> tones = {"Light", "Normal", "Dark"};

    FolderCustomizerWindow();

    void hide_show_advanced_settings();  // LATER
    void deleteSelectedItem();
    void clearAll();

    void createRegistryKey(HKEY hKeyRoot,
                           LPCSTR subKey,
                           LPCSTR valueName,
                           LPCSTR value);
    void installRegistry();
    void uninstallRegistry();

    void apply();
    void reset();

    void folderColorizeTagger(QString folderPath,
                              QString tone,
                              QString color,
                              QString tag);

   private:
    ListBoxwidget* listview;

    QPushButton* install_key_btn;
    QPushButton* uninstall_key_btn;
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