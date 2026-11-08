/// Relógio injetável: use cases recebem um [Now] para que os testes sejam
/// determinísticos.
typedef Now = DateTime Function();

/// Relógio real, sempre em UTC.
DateTime systemNow() => DateTime.now().toUtc();
