#pragma once

// #include <QtCore/QList>
// #include <QtCore/QString>

#include <string>
#include <vector>

class Settings {
   public:
    static Settings& getInstance() {
        static Settings instance;
        return instance;
    }

    std::vector<std::string> colors = {"Red",    "Brown", "Orange", "Lemon",
                                       "Green",  "Azure", "Blue",   "Pink",
                                       "Violet", "White", "Gray",   "Black"};
    std::vector<std::string> tones = {"Light", "Normal", "Dark"};
};