#pragma once

#include <QtCore/QList>
#include <QtCore/QString>

class Settings {
   public:
    static Settings& getInstance() {
        static Settings instance;
        return instance;
    }

    QList<QString> colors = {"Red",    "Brown", "Orange", "Lemon",
                             "Green",  "Azure", "Blue",   "Pink",
                             "Violet", "White", "Gray",   "Black"};
    QList<QString> tones = {"Light", "Normal", "Dark"};
};