#include "UserInterface/subclass.h"

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
    QObject::connect(button, &QPushButton::clicked, this,
                     &MessageBoxwLabel::click);
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
eTableWidget::eTableWidget() {
    this->viewport()->setAcceptDrops(true);
    this->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
    this->setSelectionMode(QAbstractItemView::ExtendedSelection);
    this->setDragDropMode(QAbstractItemView::DragDrop);
    this->setDropIndicatorShown(true);

    // Remove column grid lines, keep row grid lines
    this->setShowGrid(true);
    this->setStyleSheet(
        "QTableWidget::item { border-left: 0px; border-right: 0px; }");
}

void eTableWidget::dragEnterEvent(QDragEnterEvent* event) {
    event->accept();
}

void eTableWidget::dragMoveEvent(QDragMoveEvent* event) {
    if (!(event->mimeData()->hasUrls())) {
        event->ignore();
        return;
    }

    event->accept();
}

void eTableWidget::dropEvent(QDropEvent* event) {
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

QList<QString> eTableWidget::getAllItems() {
    this->dir_list.clear();

    for (int i = 0; i != this->rowCount(); i++) {
        QString url = this->item(i, 0)->text();
        this->dir_list.append(url);
    }
    return this->dir_list;
}

QStringList eTableWidget::removeDuplicates(const QStringList labels) {
    QStringList nodup;

    QStringList contents = this->getAllItems();

    for (auto i : labels) {
        if (!contents.contains(i)) {
            nodup.append(i);
        }
    }

    return nodup;
}

void eTableWidget::ov_addItems(const QStringList labels) {
    // remove item on the list that are duplicates

    // (const_cast<QStringList*>(labels))->removeDuplicates();

    qDebug() << (labels);

    QStringList nodup = this->removeDuplicates(labels);

    qDebug() << (nodup);
    for (QString item : nodup) {
        this->addItem(item);
    }
}

void eTableWidget::addItem(QString item) {
    int row = this->rowCount();
    this->insertRow(row);
    QTableWidgetItem* newItem = new QTableWidgetItem(item);
    this->setItem(row, 0, newItem);

    QPushButton* button = new QPushButton();
    button->setIcon(QIcon(":/icons/delete"));
    button->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
    QWidget* cellWidget = new QWidget();
    QHBoxLayout* layout = new QHBoxLayout(cellWidget);
    layout->addWidget(button);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(0);
    cellWidget->setLayout(layout);
    this->setCellWidget(row, 1, cellWidget);

    connect(button, &QPushButton::clicked, this,
            [this, row]() { this->removeItem(row); });
}

void eTableWidget::removeItem(int index) {
    QList<QTableWidgetSelectionRange> ranges = this->selectedRanges();
    if (ranges.size() > 0) {
        QList<int> rowsToRemove;
        for (const QTableWidgetSelectionRange& range : ranges) {
            for (int r = range.topRow(); r <= range.bottomRow(); ++r) {
                rowsToRemove.append(r);
            }
        }
        std::sort(rowsToRemove.begin(), rowsToRemove.end(),
                  std::greater<int>());
        ;
        for (int r : rowsToRemove) {
            this->removeRow(r);
        }
        return;
    }

    this->removeRow(index);
}

// + QGroupBox
ModGroupBox::ModGroupBox(QString title) : QGroupBox(title) {
    this->setCheckable(true);
    this->setChecked(true);
}