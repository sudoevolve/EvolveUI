// 实现文件：AudioMetadata 与 MusicLibrary 的实现
#include "core/music.h"

#include <QMediaPlayer>
#include <QAudioOutput>
#include <QCoreApplication>
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QDirIterator>
#include <QStandardPaths>
#include <QImage>
#include <QPixmap>
#include <QFileSystemWatcher>
#include <QTimer>

// ---------------------- AudioMetadata ----------------------
AudioMetadata::AudioMetadata(QObject *parent)
    : QObject(parent)
    , m_mediaPlayer(new QMediaPlayer(this))
    , m_audioOutput(new QAudioOutput(this))
    , m_duration(0)
{
    m_mediaPlayer->setAudioOutput(m_audioOutput);
    connect(m_mediaPlayer, &QMediaPlayer::metaDataChanged,
            this, &AudioMetadata::onMetaDataChanged);
    connect(m_mediaPlayer, &QMediaPlayer::durationChanged,
            this, &AudioMetadata::onDurationChanged);
}

AudioMetadata::~AudioMetadata()
{
    if (!m_tempCoverPath.isEmpty()) {
        QFile::remove(m_tempCoverPath);
    }
}

void AudioMetadata::setSource(const QString &source)
{
    if (m_source != source) {
        m_source = source;
        emit sourceChanged();

        m_title.clear();
        m_artist.clear();
        m_album.clear();
        m_coverImageUrl.clear();
        m_duration = 0;

        if (!m_tempCoverPath.isEmpty()) {
            QFile::remove(m_tempCoverPath);
            m_tempCoverPath.clear();
        }

        loadMetadata();
    }
}

void AudioMetadata::loadMetadata()
{
    if (m_source.isEmpty()) return;

    // 设置媒体源
    if (m_source.startsWith("qrc:/")) {
        m_mediaPlayer->setSource(QUrl(m_source));
    } else {
        m_mediaPlayer->setSource(QUrl::fromLocalFile(m_source));
    }
}

void AudioMetadata::onMetaDataChanged()
{
    const QMediaMetaData metaData = m_mediaPlayer->metaData();

    // 标题
    if (metaData.value(QMediaMetaData::Title).isValid()) {
        m_title = metaData.value(QMediaMetaData::Title).toString();
    } else {
        m_title = extractFileNameTitle(m_source);
    }
    emit titleChanged();

    // 艺术家
    if (metaData.value(QMediaMetaData::AlbumArtist).isValid()) {
        m_artist = metaData.value(QMediaMetaData::AlbumArtist).toString();
    } else if (metaData.value(QMediaMetaData::ContributingArtist).isValid()) {
        m_artist = metaData.value(QMediaMetaData::ContributingArtist).toString();
    } else {
        m_artist = QStringLiteral("未知艺术家");
    }
    emit artistChanged();

    // 专辑
    if (metaData.value(QMediaMetaData::AlbumTitle).isValid()) {
        m_album = metaData.value(QMediaMetaData::AlbumTitle).toString();
    } else {
        m_album = QStringLiteral("未知专辑");
    }
    emit albumChanged();

    // 封面
    extractCoverArt();
    emit metadataLoaded();
}

void AudioMetadata::onDurationChanged(qint64 duration)
{
    m_duration = static_cast<int>(duration / 1000);
    emit durationChanged();
}

void AudioMetadata::extractCoverArt()
{
    const QMediaMetaData metaData = m_mediaPlayer->metaData();
    QVariant coverData;

    if (metaData.value(QMediaMetaData::CoverArtImage).isValid()) {
        coverData = metaData.value(QMediaMetaData::CoverArtImage);
    } else if (metaData.value(QMediaMetaData::ThumbnailImage).isValid()) {
        coverData = metaData.value(QMediaMetaData::ThumbnailImage);
    }

    if (coverData.isValid()) {
        QImage coverImage;
        if (coverData.canConvert<QImage>()) {
            coverImage = coverData.value<QImage>();
        } else if (coverData.canConvert<QPixmap>()) {
            coverImage = coverData.value<QPixmap>().toImage();
        } else if (coverData.canConvert<QByteArray>()) {
            QByteArray imageData = coverData.toByteArray();
            coverImage.loadFromData(imageData);
        }

        if (!coverImage.isNull()) {
            QString tempDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
            m_tempCoverPath = tempDir + "/music_cover_" + QString::number(QCoreApplication::applicationPid()) + ".png";
            if (coverImage.save(m_tempCoverPath, "PNG")) {
                m_coverImageUrl = QUrl::fromLocalFile(m_tempCoverPath);
                emit coverImageUrlChanged();
            }
        }
    } else {
        m_coverImageUrl = QUrl();
        emit coverImageUrlChanged();
    }
}

QString AudioMetadata::extractFileNameTitle(const QString &filePath)
{
    QFileInfo fileInfo(filePath);
    QString baseName = fileInfo.baseName();
    if (baseName.contains(" - ")) {
        QStringList parts = baseName.split(" - ");
        if (parts.size() >= 2) return parts.last().trimmed();
    }
    return baseName;
}

// ---------------------- MusicLibrary ----------------------
MusicLibrary::MusicLibrary(QObject *parent)
    : QObject(parent)
    , m_watcher(new QFileSystemWatcher(this))
    , m_scanTimer(new QTimer(this))
    , m_isWatching(false)
{
    // 配置扫描定时器
    m_scanTimer->setSingleShot(true);
    m_scanTimer->setInterval(SCAN_DELAY_MS);
    m_lastScanMs = 0;
    
    // 连接信号
    connect(m_watcher, &QFileSystemWatcher::directoryChanged,
            this, &MusicLibrary::onDirectoryChanged);
    connect(m_watcher, &QFileSystemWatcher::fileChanged,
            this, &MusicLibrary::onFileChanged);
    connect(m_scanTimer, &QTimer::timeout,
            this, &MusicLibrary::performDelayedScan);
}

QStringList MusicLibrary::scanMusicFiles(const QString &rootPath, bool recursive)
{
    QStringList musicFiles;
    if (rootPath.isEmpty()) return musicFiles;

    QDir dir(rootPath);
    if (!dir.exists()) return musicFiles;

    QStringList extensions = getValidMusicExtensions();
    QStringList nameFilters;
    for (const QString &ext : extensions) {
        nameFilters << QString("*.%1").arg(ext);
    }

    QDirIterator::IteratorFlag flag = recursive ? QDirIterator::Subdirectories : QDirIterator::NoIteratorFlags;
    QDirIterator it(rootPath, nameFilters, QDir::Files, flag);

    while (it.hasNext()) {
        QString filePath = it.next();
        if (isValidMusicFile(filePath)) {
            musicFiles.append(filePath);
        }
    }

    return musicFiles;
}

QString MusicLibrary::defaultProjectRoot()
{
    return findProjectRootFromAppDir();
}

QStringList MusicLibrary::scanDefaultProjectMusic(bool recursive)
{
    return scanMusicFiles(defaultProjectRoot(), recursive);
}

QString MusicLibrary::findProjectRootFromAppDir() const
{
    QString appDir = QCoreApplication::applicationDirPath();
    QDir dir(appDir);

    // 向上查找最多6级目录
    for (int i = 0; i < 6; ++i) {
        if (dir.exists("src.qrc") || dir.exists("components")) {
            return dir.absolutePath();
        }
        if (!dir.cdUp()) break;
    }

    return appDir; // 默认返回应用程序目录
}

// 新增：获取Windows音乐文件夹路径
QString MusicLibrary::getWindowsMusicFolder()
{
    return QStandardPaths::writableLocation(QStandardPaths::MusicLocation);
}

// 新增：扫描Windows音乐文件夹
QStringList MusicLibrary::scanWindowsMusic(bool recursive)
{
    QString windowsMusicPath = getWindowsMusicFolder();
    if (windowsMusicPath.isEmpty()) {
        return QStringList();
    }
    return scanMusicFiles(windowsMusicPath, recursive);
}

// 新增：扫描所有可用音乐（项目+Windows音乐文件夹）
QStringList MusicLibrary::scanAllAvailableMusic(bool recursive)
{
    QStringList allMusic;
    
    // 首先扫描项目音乐
    QStringList projectMusic = scanDefaultProjectMusic(recursive);
    allMusic.append(projectMusic);
    
    // 如果项目中没有音乐文件，则扫描Windows音乐文件夹
    if (projectMusic.isEmpty()) {
        QStringList windowsMusic = scanWindowsMusic(recursive);
        allMusic.append(windowsMusic);
    }
    
    // 更新缓存
    m_cachedFiles = allMusic;
    
    return allMusic;
}

// 查找与音源同名同目录的 LRC，或项目根目录回退
QString MusicLibrary::findLyricsFileForSource(const QString &source)
{
    if (source.isEmpty()) return QString();

    // 优先：同名同目录
    auto trySameDir = [&](const QString &localPath) -> QString {
        QFileInfo fi(localPath);
        if (!fi.exists()) return QString();
        QString candidate = fi.dir().absoluteFilePath(fi.completeBaseName() + ".lrc");
        if (QFile::exists(candidate)) {
            return QUrl::fromLocalFile(candidate).toString();
        }
        // 兼容：若同名未命中且目录内只有一个 .lrc，则使用该文件
        QStringList lrcs = fi.dir().entryList(QStringList() << "*.lrc", QDir::Files, QDir::Name);
        if (lrcs.size() == 1) {
            QString onlyLrc = fi.dir().absoluteFilePath(lrcs.first());
            if (QFile::exists(onlyLrc)) {
                return QUrl::fromLocalFile(onlyLrc).toString();
            }
        }
        return QString();
    };

    if (source.startsWith("file:///")) {
        QUrl u(source);
        QString localPath = u.toLocalFile();
        QString hit = trySameDir(localPath);
        if (!hit.isEmpty()) return hit;
    } else if (source.startsWith("qrc:/")) {
        // qrc: 路径下尝试根据文件名在项目根目录匹配
        QUrl u(source);
        QFileInfo fi(u.path());
        QString baseName = fi.completeBaseName();
        QString root = defaultProjectRoot();
        QString candidate = QDir(root).absoluteFilePath(baseName + ".lrc");
        if (QFile::exists(candidate)) {
            return QUrl::fromLocalFile(candidate).toString();
        }
    } else {
        // 普通本地路径
        QString hit = trySameDir(source);
        if (!hit.isEmpty()) return hit;
    }

    // 回退：项目根目录第一个 .lrc 文件（避免完全无歌词）
    QString root = defaultProjectRoot();
    QDirIterator it(root, QStringList() << "*.lrc", QDir::Files, QDirIterator::NoIteratorFlags);
    if (it.hasNext()) {
        QString p = it.next();
        return QUrl::fromLocalFile(p).toString();
    }
    return QString();
}

// 读取歌词文本（UTF-8优先，回退本地编码）
QString MusicLibrary::loadLyricsText(const QString &source)
{
    QString lrcUrl = findLyricsFileForSource(source);
    if (lrcUrl.isEmpty()) return QString();
    QUrl u(lrcUrl);
    QString lrcPath = u.toLocalFile();
    if (lrcPath.isEmpty()) {
        // 兜底：如果传入的就是本地路径
        lrcPath = lrcUrl;
    }
    QFile f(lrcPath);
    if (!f.exists()) return QString();
    if (f.open(QIODevice::ReadOnly)) {
        QByteArray bytes = f.readAll();
        f.close();
        // 尝试UTF-8
        QString text = QString::fromUtf8(bytes);
        // 若解码后基本为空，则回退本地编码
        if (text.trimmed().isEmpty() && !bytes.isEmpty()) {
            text = QString::fromLocal8Bit(bytes);
        }
        return text;
    }
    return QString();
}

// 新增：文件监控功能
void MusicLibrary::startWatching()
{
    if (m_isWatching) return;
    
    m_isWatching = true;
    m_watchedPaths.clear();
    
    // 添加项目根目录到监控
    QString projectRoot = defaultProjectRoot();
    if (!projectRoot.isEmpty()) {
        addWatchPath(projectRoot);
        qDebug() << "开始监控项目根目录:" << projectRoot;
    }
    
    // 添加Windows音乐文件夹到监控
    QString windowsMusic = getWindowsMusicFolder();
    if (!windowsMusic.isEmpty()) {
        addWatchPath(windowsMusic);
        qDebug() << "开始监控Windows音乐文件夹:" << windowsMusic;
    }
    
    qDebug() << "文件监控已启动，监控路径数量:" << m_watchedPaths.size();
    for (const QString &path : m_watchedPaths) {
        qDebug() << "  监控路径:" << path;
    }
}

void MusicLibrary::stopWatching()
{
    if (!m_isWatching) return;
    
    m_isWatching = false;
    m_watcher->removePaths(m_watchedPaths);
    m_watchedPaths.clear();
    m_scanTimer->stop();
}

bool MusicLibrary::isWatching() const
{
    return m_isWatching;
}

// 新增：缓存管理
void MusicLibrary::clearCache()
{
    m_cachedFiles.clear();
}

int MusicLibrary::getCachedFileCount() const
{
    return m_cachedFiles.size();
}

// 新增：文件监控槽函数
void MusicLibrary::onDirectoryChanged(const QString &path)
{
    qDebug() << "检测到目录变化:" << path;
    
    // 检查路径是否仍然存在
    QDir dir(path);
    if (!dir.exists()) {
        qDebug() << "目录已被删除:" << path;
        // 重新添加父目录到监控（如果存在）
        QDir parentDir = dir;
        if (parentDir.cdUp() && parentDir.exists()) {
            m_watcher->addPath(parentDir.absolutePath());
            qDebug() << "添加父目录到监控:" << parentDir.absolutePath();
        }
    }
    
    // 延迟扫描以避免频繁更新
    m_scanTimer->start();
}

void MusicLibrary::onFileChanged(const QString &path)
{
    qDebug() << "检测到文件变化:" << path;
    
    // 检查文件是否仍然存在
    QFileInfo fileInfo(path);
    if (!fileInfo.exists()) {
        qDebug() << "文件已被删除或移动:" << path;
        // 从监控中移除
        m_watcher->removePath(path);
    } else {
        qDebug() << "文件已修改:" << path;
    }
    
    // 延迟扫描以避免频繁更新
    m_scanTimer->start();
}

void MusicLibrary::performDelayedScan()
{
    if (!m_isWatching) return;
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    if (m_lastScanMs > 0 && (now - m_lastScanMs) < 7000) {
        // 退抖：7s 内不重复全量扫描
        m_scanTimer->start();
        return;
    }
    m_lastScanMs = now;
    
    // 重新扫描所有音乐文件
    QStringList newFiles = scanAllAvailableMusic(true);
    
    // 检查是否有变化
    if (newFiles != m_cachedFiles) {
        // 找出新增和删除的文件
        QStringList addedFiles;
        QStringList removedFiles;
        
        for (const QString &file : newFiles) {
            if (!m_cachedFiles.contains(file)) {
                addedFiles.append(file);
            }
        }
        
        for (const QString &file : m_cachedFiles) {
            if (!newFiles.contains(file)) {
                removedFiles.append(file);
            }
        }
        
        // 更新缓存
        m_cachedFiles = newFiles;
        
        // 发送信号
        emit musicFilesChanged(newFiles);
        
        for (const QString &file : addedFiles) {
            emit fileAdded(file);
        }
        
        for (const QString &file : removedFiles) {
            emit fileRemoved(file);
        }
        
        // 输出调试信息
        qDebug() << "音乐文件变化检测:";
        qDebug() << "  总文件数:" << newFiles.size();
        qDebug() << "  新增文件:" << addedFiles.size();
        qDebug() << "  删除文件:" << removedFiles.size();
        if (!removedFiles.isEmpty()) {
            qDebug() << "  删除的文件:" << removedFiles;
        }
    }
}

// 新增：辅助方法
QStringList MusicLibrary::getValidMusicExtensions() const
{
    return QStringList() << "mp3" << "m4a" << "flac" << "wav" << "ogg" << "aac";
}

bool MusicLibrary::isValidMusicFile(const QString &filePath) const
{
    QFileInfo fileInfo(filePath);
    if (!fileInfo.exists() || !fileInfo.isFile()) {
        return false;
    }
    
    QString extension = fileInfo.suffix().toLower();
    return getValidMusicExtensions().contains(extension);
}

void MusicLibrary::addWatchPath(const QString &path)
{
    if (path.isEmpty() || m_watchedPaths.contains(path)) {
        return;
    }
    
    QDir dir(path);
    if (!dir.exists()) {
        return;
    }
    
    m_watchedPaths.append(path);
    m_watcher->addPath(path);
    // 取消递归子目录监控，避免大量事件导致频繁全量扫描
}

void MusicLibrary::updateFileCache()
{
    m_cachedFiles = scanAllAvailableMusic(true);
}
