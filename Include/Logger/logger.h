#ifndef LOGGER_H
#define LOGGER_H

#include <QtCore/QDateTime>
#include <QtCore/QFile>
#include <QtCore/QTextStream>
#include <QtCore/QVariant>

#include <QtCore/QDataStream>
#include <QtCore/QFileInfo>
#include <string>

#include <map>

namespace LOGGER {
enum STATUS { WARN, INFO };
enum PRIORITY { HIG, MID, LOW };
enum CHRONOLOGY { BEF, DUR, AFT };
}  // namespace LOGGER

class Logger {
   public:
    Logger();
    Logger(QString name);

    void write(QVariant message,
               LOGGER::CHRONOLOGY chronology,
               LOGGER::STATUS status = LOGGER::STATUS::INFO,
               LOGGER::PRIORITY priority = LOGGER::PRIORITY::LOW);

   private:
    QString* m_fileName;
    QFile* m_file = new QFile();
    bool m_isWritable;
    QTextStream* m_textStream;

    // QFile* mt_file;

    QString generateAutoName();
};

#endif