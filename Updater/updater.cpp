#include <QtCore/QDir>
#include <QtCore/QEventLoop>
#include <QtCore/QFile>
#include <QtCore/QFileDevice>
#include <QtCore/QFileInfo>
#include <QtCore/QJsonArray>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QProcess>
#include <QtCore/QRegularExpression>
#include <QtCore/QStandardPaths>
#include <QtCore/QSysInfo>
#include <QtCore/QTextStream>
#include <QtCore/QTimer>
#include <QtCore/QUrl>
#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkReply>
#include <QtNetwork/QNetworkRequest>
#include <QtWidgets/QApplication>
#include <QtWidgets/QLabel>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMessageBox>
#include <QtWidgets/QProgressBar>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QTextEdit>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>
#include <functional>

class UpdaterWindow : public QMainWindow {
    Q_OBJECT

   public:
    explicit UpdaterWindow(QWidget* parent = nullptr)
        : QMainWindow(parent), networkManager(new QNetworkAccessManager(this)) {
        setWindowTitle("Folder Customizer Updater");

        auto* central = new QWidget(this);
        auto* layout = new QVBoxLayout(central);

        statusLabel = new QLabel("Starting...", central);
        progressBar = new QProgressBar(central);
        progressBar->setRange(0, 0);  // indeterminate until we get sizes
        actionButton = new QPushButton("Cancel", central);
        connect(actionButton, &QPushButton::clicked, this, [this]() {
            if (currentReply)
                currentReply->abort();
            close();
        });

        layout->addWidget(statusLabel);
        layout->addWidget(progressBar);
        logView = new QTextEdit(central);
        logView->setReadOnly(true);
        logView->setMinimumHeight(150);
        layout->addWidget(logView);
        layout->addWidget(actionButton);
        setCentralWidget(central);

        // Kick off the flow
        QTimer::singleShot(0, this, &UpdaterWindow::start);
    }

   private slots:
    void start() {
        statusLabel->setText("Downloading manifest...");
        progressBar->setRange(0, 0);
        // Log detected OS/distro for user visibility
        log(QString("OS: %1").arg(QSysInfo::prettyProductName()));
#ifdef Q_OS_LINUX
        log("Linux family detected: " + detectLinuxFamily());
#endif
        fetch(manifestUrl(), [this](QNetworkReply* reply) {
            if (!checkReplyOk(reply, "manifest"))
                return;
            const QByteArray manifestBytes = reply->readAll();
            reply->deleteLater();

            const QString remoteVersion =
                extractJsonString(manifestBytes, "version");
            const QString localVersion = readLocalVersion();

            if (compareVersions(localVersion, remoteVersion) >= 0) {
                statusLabel->setText("Up to date (" + localVersion + ")");
                progressBar->setRange(0, 1);
                progressBar->setValue(1);
                actionButton->setText("Close");
                return;
            }

            // Ask to update
            if (QMessageBox::question(this, "Update Available",
                                      "Update to " + remoteVersion + " now?") !=
                QMessageBox::Yes) {
                statusLabel->setText("Update canceled");
                actionButton->setText("Close");
                progressBar->setRange(0, 1);
                progressBar->setValue(1);
                return;
            }

            statusLabel->setText("Querying release assets...");
            progressBar->setRange(0, 0);
            fetch(latestReleaseApiUrl(), [this](QNetworkReply* r) {
                if (!checkReplyOk(r, "release assets"))
                    return;
                const QJsonDocument doc = QJsonDocument::fromJson(r->readAll());
                r->deleteLater();
                if (!doc.isObject())
                    return fail("Invalid releases API response");
                const QJsonArray assets =
                    doc.object().value("assets").toArray();

                const QString assetUrl = chooseAssetUrl(assets);
                if (assetUrl.isEmpty()) {
                    return fail(
                        "No suitable installer asset found for your OS/distro");
                }

                log("Selected asset: " + selectedAssetName + " -> " + assetUrl);

                // Download installer with progress
                statusLabel->setText("Downloading installer...");
                downloadToTemp(assetUrl, [this, assetUrl](const QString& path) {
                    if (path.isEmpty())
                        return fail("Failed to download installer (" +
                                    assetUrl + ")");
                    runInstaller(path);
                });
            });
        });
    }

   private:
    QLabel* statusLabel{nullptr};
    QProgressBar* progressBar{nullptr};
    QPushButton* actionButton{nullptr};
    QNetworkAccessManager* networkManager{nullptr};
    QNetworkReply* currentReply{nullptr};
    QTextEdit* logView{nullptr};
    QString selectedAssetName;
    QString selectedAssetUrl;

    static QString manifestUrl() {
        return QStringLiteral(
            "https://raw.githubusercontent.com/Deadbush225/Folder-Customizer/"
            "main/manifest.json");
    }
    static QString latestReleaseApiUrl() {
        return QStringLiteral(
            "https://api.github.com/repos/Deadbush225/Folder-Customizer/"
            "releases/latest");
    }

    void fetch(const QString& url, std::function<void(QNetworkReply*)> cb) {
        QNetworkRequest req(url);
        req.setRawHeader("User-Agent", "FolderCustomizer-Updater");
        currentReply = networkManager->get(req);
        connect(currentReply, &QNetworkReply::finished, this, [this, cb]() {
            auto* r = currentReply;
            currentReply = nullptr;
            cb(r);
        });
    }

    void downloadToTemp(const QString& url, std::function<void(QString)> cb) {
        QNetworkRequest req(url);
        req.setRawHeader("User-Agent", "FolderCustomizer-Updater");
        currentReply = networkManager->get(req);

        progressBar->setRange(0, 0);
        connect(currentReply, &QNetworkReply::downloadProgress, this,
                [this](qint64 rec, qint64 tot) {
                    if (tot > 0) {
                        progressBar->setRange(0, static_cast<int>(tot));
                        progressBar->setValue(static_cast<int>(rec));
                    }
                });

        connect(currentReply, &QNetworkReply::finished, this,
                [this, url, cb]() {
                    auto* r = currentReply;
                    currentReply = nullptr;
                    if (r->error() != QNetworkReply::NoError) {
                        const QString err = r->errorString();
                        r->deleteLater();
                        QMessageBox::critical(this, "Download Error", err);
                        cb(QString());
                        return;
                    }

                    // Save using the asset file name
                    const QString fileName = QUrl(url).fileName();
                    const QString outPath = QDir::tempPath() + "/" + fileName;
                    QFile f(outPath);
                    if (!f.open(QIODevice::WriteOnly)) {
                        r->deleteLater();
                        QMessageBox::critical(this, "File Error",
                                              "Cannot write " + outPath);
                        cb(QString());
                        return;
                    }
                    f.write(r->readAll());
                    f.close();
                    r->deleteLater();
                    log("Saved installer to: " + outPath);
                    cb(outPath);
                });
    }

    bool checkReplyOk(QNetworkReply* r, const QString& what) {
        if (r->error() == QNetworkReply::NoError)
            return true;
        const QString err = r->errorString();
        r->deleteLater();
        fail("Failed to download " + what + ": " + err);
        return false;
    }

    void fail(const QString& msg) {
        statusLabel->setText(msg);
        progressBar->setRange(0, 1);
        progressBar->setValue(0);
        actionButton->setText("Close");
    }

    void log(const QString& msg) {
        if (logView) {
            logView->append(msg);
        }
    }

    QString readLocalVersion() const {
        const QString localManifestPath =
            QCoreApplication::applicationDirPath() + "/manifest.json";
        QFile file(localManifestPath);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
            return "0.0.0";
        const QByteArray content = file.readAll();
        file.close();
        return extractJsonString(content, "version");
    }

    static int compareVersions(const QString& a, const QString& b) {
        const auto sa = a.split('.');
        const auto sb = b.split('.');
        const int n = qMax(sa.size(), sb.size());
        for (int i = 0; i < n; ++i) {
            int ai = i < sa.size() ? sa[i].toInt() : 0;
            int bi = i < sb.size() ? sb[i].toInt() : 0;
            if (ai != bi)
                return ai < bi ? -1 : 1;
        }
        return 0;
    }

    static QString extractJsonString(const QByteArray& json, const char* key) {
        const QJsonDocument doc = QJsonDocument::fromJson(json);
        if (!doc.isObject())
            return {};
        return doc.object().value(QLatin1String(key)).toString();
    }

    static QString detectLinuxFamily() {
#if defined(Q_OS_LINUX)
        QFile f("/etc/os-release");
        if (f.open(QIODevice::ReadOnly | QIODevice::Text)) {
            const QString data = QString::fromUtf8(f.readAll()).toLower();
            if (data.contains("debian") || data.contains("ubuntu"))
                return "deb";
            if (data.contains("arch") || data.contains("manjaro"))
                return "arch";
            if (data.contains("fedora") || data.contains("rhel") ||
                data.contains("centos") || data.contains("suse"))
                return "rpm";
        }
#endif
        return "unknown";
    }

    static bool nameMatches(const QString& name, const QString& pattern) {
        return QRegularExpression(pattern,
                                  QRegularExpression::CaseInsensitiveOption)
            .match(name)
            .hasMatch();
    }

    QString chooseAssetUrl(const QJsonArray& assets) {
        selectedAssetName.clear();
        selectedAssetUrl.clear();
#ifdef Q_OS_WIN
        // Windows: exact EXE
        for (const auto& v : assets) {
            const QJsonObject a = v.toObject();
            const QString name = a.value("name").toString();
            if (name == "FolderCustomizerSetup-x64.exe") {
                selectedAssetName = name;
                selectedAssetUrl = a.value("browser_download_url").toString();
                return selectedAssetUrl;
            }
        }
        return {};
#elif defined(Q_OS_LINUX)
        const QString fam = detectLinuxFamily();
        QStringList patterns;
        if (fam == "deb") {
            patterns
                << R"(folder-customizer_[0-9]+\.[0-9]+\.[0-9]+_amd64\.deb$)";
        } else if (fam == "rpm") {
            patterns
                << R"(folder-customizer-[0-9]+\.[0-9]+\.[0-9]+-\d+\.x86_64\.rpm$)";
        } else if (fam == "arch") {
            // Only accept a real makepkg .pkg.tar.* if present; otherwise fall
            // back
            patterns
                << R"(folder-customizer-[0-9]+\.[0-9]+\.[0-9]+-\d+-x86_64\.pkg\.(tar\.)?(zst|gz)$)";
        }
        // Fallbacks
        patterns
            << R"(FolderCustomizer-[0-9]+\.[0-9]+\.[0-9]+-x86_64\.AppImage$)";
        patterns
            << R"(FolderCustomizer-[0-9]+\.[0-9]+\.[0-9]+-x86_64\.tar\.gz$)";

        for (const auto& v : assets) {
            const QJsonObject a = v.toObject();
            const QString name = a.value("name").toString();
            for (const auto& pat : patterns)
                if (nameMatches(name, pat)) {
                    selectedAssetName = name;
                    selectedAssetUrl =
                        a.value("browser_download_url").toString();
                    return selectedAssetUrl;
                }
        }
        return {};
#else
        return {};
#endif
    }

    void runInstaller(const QString& path) {
#ifdef Q_OS_WIN
        statusLabel->setText("Launching installer...");
        progressBar->setRange(0, 1);
        progressBar->setValue(1);
        if (!QProcess::startDetached(path, {})) {
            return fail("Failed to run installer");
        }
        close();
#elif defined(Q_OS_LINUX)
        const QString lower = path.toLower();
        QString cmd;
        QStringList args;
        if (lower.endsWith(".deb")) {
            cmd = "pkexec";
            args << "dpkg" << "-i" << path;
        } else if (lower.endsWith(".rpm")) {
            cmd = "pkexec";
            args << "rpm" << "-Uvh" << path;
        } else if (lower.contains(".pkg.tar")) {
            cmd = "pkexec";
            args << "pacman" << "-U" << "--noconfirm" << path;
        } else if (lower.endsWith(".tar.gz")) {
            // Extract and run install.sh directly with pkexec
            const QString outDir = QDir::tempPath() + "/fc-install";
            QDir().mkpath(outDir);
            if (QProcess::execute(
                    "bash",
                    {"-lc", QString("mkdir -p '%1' && tar xzf '%2' -C '%1' && "
                                    "chmod +x '%1/install.sh' 2>/dev/null || "
                                    "true && pkexec bash '%1/install.sh'")
                                .arg(outDir, path)}) != 0) {
                return fail("Extraction/installation failed");
            }
            close();
            return;
        } else if (lower.endsWith(".appimage")) {
            // As a last resort: run AppImage directly
            QFile(path).setPermissions(
                QFile::permissions(path) | QFileDevice::ExeOwner |
                QFileDevice::ExeGroup | QFileDevice::ExeOther);
            if (!QProcess::startDetached(path, {}))
                return fail("Failed to run AppImage");
            close();
            return;
        } else {
            return fail("Unknown installer format");
        }

        statusLabel->setText("Requesting privileges and installing...");
        progressBar->setRange(0, 0);
        auto* proc = new QProcess(this);
        connect(proc, &QProcess::errorOccurred, this,
                [this, proc](QProcess::ProcessError) {
                    fail("Failed to invoke installer");
                    proc->deleteLater();
                });
        connect(
            proc, qOverload<int, QProcess::ExitStatus>(&QProcess::finished),
            this, [this, proc](int code, QProcess::ExitStatus) {
                if (code == 0) {
                    statusLabel->setText("Installation finished.");
                    progressBar->setRange(0, 1);
                    progressBar->setValue(1);
                    close();
                } else {
                    fail("Installer exited with code " + QString::number(code));
                }
                proc->deleteLater();
            });
        proc->start(cmd, args);
        if (!proc->waitForStarted(3000)) {
            proc->deleteLater();
            return fail("Failed to start installer");
        }
        statusLabel->setText(
            "Installer running, please complete the prompts...");
#else
        Q_UNUSED(path);
        fail("Unsupported OS");
#endif
    }
};

#include "updater.moc"

int main(int argc, char* argv[]) {
    QApplication app(argc, argv);
    UpdaterWindow w;
    w.resize(420, 140);
    w.show();
    return app.exec();
}
