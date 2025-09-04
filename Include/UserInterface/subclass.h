#ifndef SUBCLASS_H
#define SUBCLASS_H

#include <QtCore/QObject>
#include <QtWidgets/QAbstractItemView>
#include <QtWidgets/QCheckBox>
#include <QtWidgets/QDialog>
#include <QtWidgets/QFrame>
#include <QtWidgets/QGroupBox>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QListWidget>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QSizePolicy>
#include <QtWidgets/QVBoxLayout>

#include <QtGui/QDragEnterEvent>
#include <QtGui/QDragMoveEvent>
#include <QtGui/QDropEvent>

#include <QtCore/QDebug>
#include <QtCore/QMimeData>
#include <QtCore/QUrl>

class QHSeparationLine : public QFrame {
   public:
    QHSeparationLine();
};

class ModQHBoxLayout : public QHBoxLayout {
   public:
    ModQHBoxLayout();
};

class ModQLabel : public QLabel {
   public:
    ModQLabel(QString str);
};

class MessageBoxwLabel : public QDialog {
    Q_OBJECT

   public:
    MessageBoxwLabel(QString folder);

   public slots:
    void click();

   private:
    QString folder_name;

    QCheckBox* addTag_chkbx;
    QLineEdit* lineEdit;

    QString tag_from_popup;
    bool addTag;
};

class ListBoxwidget : public QListWidget {
   public:
    ListBoxwidget();
    QList<QString> getAllItems();
    using QListWidget::selectedIndexes;

   protected:
    void dragEnterEvent(QDragEnterEvent* event) override;
    void dragMoveEvent(QDragMoveEvent* event) override;
    void dropEvent(QDropEvent* event) override;
    void ov_addItems(const QStringList labels);

    QStringList removeDuplicates(const QStringList labels);

   private:
    QList<QString> dir_list;
};

class ModGroupBox : public QGroupBox {
   public:
    ModGroupBox(QString title);
};

#endif