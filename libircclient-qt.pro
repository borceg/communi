######################################################################
# LibIrcClient-Qt
######################################################################

TEMPLATE = lib
DESTDIR = lib
TARGET = $$qtLibraryTarget(ircclient-qt)
DEPENDPATH += include src
INCLUDEPATH += include
DEFINES += BUILD_IRC
QT = core network

DEFINES += HAVE_ICU
contains(DEFINES, HAVE_ICU) {
    win32:INCLUDEPATH += C:\ICU\include
    win32:LIBS += -LC:\ICU\lib
    win32:LIBS += -l$$qtLibraryTarget(icuin)
    unix:LIBS += -licui18n
    LIBS += -l$$qtLibraryTarget(icuuc)
}

CONV_HEADERS += include/Irc include/IrcGlobal include/IrcSession include/IrcUtil
HEADERS += irc.h ircglobal.h ircsession.h ircutil.h
SOURCES += irc.cpp ircsession.cpp ircutil.cpp

mkspecs.files = libircclient-qt.prf
mkspecs.path = $$[QT_INSTALL_DATA]/mkspecs/features
INSTALLS += mkspecs

headers.files = $$HEADERS $$CONV_HEADERS
headers.path = $$[QT_INSTALL_HEADERS]/ircclient-qt
INSTALLS += headers

target.path = $$[QT_INSTALL_LIBS]
INSTALLS += target

dlltarget.path = $$[QT_INSTALL_BINS]
INSTALLS += dlltarget
