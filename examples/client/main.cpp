/*
 * Copyright (C) 2008-2013 The Communi Project
 *
 * This example is free, and not covered by the LGPL license. There is no
 * restriction applied to their modification, redistribution, using and so on.
 * You can study them, modify them, use them in your own program - either
 * completely or partially.
 */

#include <QApplication>
#include "ircclient.h"

int main(int argc, char* argv[])
{
    QApplication app(argc, argv);
    IrcClient client;
    client.resize(640, 480);
    client.show();
    return app.exec();
}
