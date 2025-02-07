#include "../../Include/Logger/logger.h"

namespace LOGGER {
std::map<STATUS, QString> status_table = {{STATUS::WARN, "WARN"},
                                          {STATUS::INFO, "INFO"}};

std::map<PRIORITY, QString> priority_table = {{PRIORITY::HIG, "HIG"},
                                              {PRIORITY::MID, "MID"},
                                              {PRIORITY::LOW, "LOW"}};

std::map<CHRONOLOGY, QString> chronology_table = {{CHRONOLOGY::BEF, "BEF"},
                                                  {CHRONOLOGY::DUR, "DUR"},
                                                  {CHRONOLOGY::AFT, "AFT"}};

};  // namespace LOGGER

Logger::Logger() : Logger(generateAutoName()) {}

Logger::Logger(QString name) {
    this->m_fileName = &name;

    qDebug() << *(this->m_fileName);

    this->m_file = new QFile(*(this->m_fileName));

    QFileInfo* fileinfo = new QFileInfo(this->m_file->filesystemFileName());
    // qDebug() << fileinfo->absoluteFilePath();

    this->m_isWritable = this->m_file->open(QIODevice::WriteOnly);

    qDebug() << this->m_isWritable;

    if (this->m_isWritable) {
        this->m_textStream = new QTextStream(this->m_file);
    }
}

// Todo: add version control inside Logger
void Logger::write(QVariant message,
                   LOGGER::CHRONOLOGY chronology,
                   LOGGER::STATUS status,
                   LOGGER::PRIORITY priority) {
    std::string t_chronology =
        LOGGER::chronology_table[chronology].toStdString().c_str();
    std::string t_status = LOGGER::status_table[status].toStdString().c_str();
    std::string t_priority =
        LOGGER::priority_table[priority].toStdString().c_str();

    QString line = QString((boost::format("[%1%][%2%][%3%]: ") % t_chronology %
                            t_status % t_priority)
                               .str()
                               .c_str());

    line.append(message.toString());

    qDebug() << line;
    qDebug() << line.toStdString().c_str();

    ///////////////////////////////

    // this->mt_file = new QFile("Test.txt");
    // this->mt_file->open(QIODevice::WriteOnly);
    QTextStream stream = QTextStream(this->m_file);
    stream << line.toStdString().c_str();
}

QString Logger::generateAutoName() {
    QDateTime date = QDateTime::currentDateTime();
    QString name = date.toString("dd-MM-yyyy [hh-mm-ss-zzz]")
                       .prepend("LOG_")
                       .append(".txt");
    // QString name = "Test.txt";
    qDebug() << name;
    return name;
}
