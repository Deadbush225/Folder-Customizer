#include "../../Include/Window/subclass.h"

// + QHSeparationLine
QHSeparationLine::QHSeparationLine() {
    this->setFixedHeight(2);
    this->setFrameShape(QFrame::HLine);
    this->setFrameShadow(QFrame::Sunken);
    this->setSizePolicy(QSizePolicy::Preferred, QSizePolicy::Minimum);
}

// + ModQHBoxLayout
ModQHBoxLayout::ModQHBoxLayout() {
    this->setAlignment(Qt::AlignTop);
}

// + ModQLabel
ModQLabel::ModQLabel(QString str) : QLabel(str) {
    this->setSizePolicy(QSizePolicy::Maximum, QSizePolicy::Maximum);
    this->setAlignment(Qt::AlignHCenter | Qt::AlignTop);
}

// + MessageBoxwLabel
MessageBoxwLabel::MessageBoxwLabel(QString folder) {
    QVBoxLayout* mainlayout = new QVBoxLayout();

    QLabel* folderLabel = new QLabel("Folder: " + folder);
    mainlayout->addWidget(folderLabel);

    addTag_chkbx = new QCheckBox("Don't add a tag");
    mainlayout->addWidget(addTag_chkbx);

    QLabel* label = new QLabel("Custom Tag?");
    mainlayout->addWidget(label);

    lineEdit = new QLineEdit();
    mainlayout->addWidget(lineEdit);

    QPushButton* button = new QPushButton("Done");
    QObject::connect(button, QPushButton::clicked, this, &click);
    mainlayout->addWidget(button);

    this->setLayout(mainlayout);

    int returned = this->exec();
}

void MessageBoxwLabel::click() {
    qDebug() << "click";

    tag_from_popup = this->lineEdit->text().simplified();  // lineedit.text();
    addTag = this->addTag_chkbx->isChecked();              // lineedit.text();
    this->done(1);
}

// + ListBoxwidget
ListBoxwidget::ListBoxwidget() {
    this->viewport()->setAcceptDrops(true);
    this->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
    this->setSelectionMode(QAbstractItemView::ExtendedSelection);
    this->setDragDropMode(QAbstractItemView::DragDrop);
    this->setDropIndicatorShown(true);
}

void ListBoxwidget::dragEnterEvent(QDragEnterEvent* event) {
    event->accept();
}

void ListBoxwidget::dragMoveEvent(QDragMoveEvent* event) {
    if (!(event->mimeData()->hasUrls())) {
        event->ignore();
        return;
    }

    event->accept();
}

void ListBoxwidget::dropEvent(QDropEvent* event) {
    if (event->mimeData()->hasUrls()) {
        event->accept();

        QList<QString> tmp_list;

        for (QUrl url : event->mimeData()->urls()) {
            if (url.isLocalFile()) {
                tmp_list.append(url.toLocalFile());
            }
        }
        this->ov_addItems(tmp_list);
        qDebug() << "Dropping";
    } else {
        event->ignore();
    }
}

QList<QString> ListBoxwidget::getAllItems() {
    this->dir_list.clear();

    for (int i = 0; i != this->count(); i++) {
        QString url = this->item(i)->text();
        this->dir_list.append(url);
    }
    return this->dir_list;
}

QStringList ListBoxwidget::removeDuplicates(const QStringList labels) {
    QStringList nodup;

    QStringList contents = this->getAllItems();

    for (auto i : labels) {
        if (!contents.contains(i)) {
            nodup.append(i);
        }
    }

    return nodup;
}

void ListBoxwidget::ov_addItems(const QStringList labels) {
    // remove item on the list that are duplicates

    // (const_cast<QStringList*>(labels))->removeDuplicates();

    qDebug() << (labels);

    QStringList nodup = this->removeDuplicates(labels);

    qDebug() << (nodup);
    this->addItems(nodup);
}

// + QGroupBox
ModGroupBox::ModGroupBox(QString title) : QGroupBox(title) {
    this->setCheckable(true);
    this->setChecked(true);
}