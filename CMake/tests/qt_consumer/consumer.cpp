#include <QApplication>
#include <QFile>
#include <QOpenGLWidget>
#include <QSvgRenderer>
#include <QTcpSocket>
#include <QVariant>
#include "ui_form.h"

class BuildProbe : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int value READ value)
public:
    int value() const { return 42; }
};

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    QWidget widget;
    Ui::Form form;
    form.setupUi(&widget);
    BuildProbe probe;
    QTcpSocket socket;
    QSvgRenderer renderer(QByteArray(
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1\" height=\"1\"/>"));
    QFile resource(":/fixture/message.txt");
    return probe.property("value").toInt() == 42
        && form.label->text() == "Native tools, target Qt"
        && resource.open(QIODevice::ReadOnly)
        && resource.readAll().trimmed() == "Native resource compiler"
        && renderer.isValid() && !socket.isOpen()
        && QOpenGLWidget::staticMetaObject.inherits(&QWidget::staticMetaObject)
        ? 0 : 1;
}

#include "consumer.moc"
