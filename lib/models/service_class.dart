enum ServiceClass {
  economy('Эконом', 1.0),
  business('Бизнес', 2.5),
  first('Первый', 4.0);

  const ServiceClass(this.label, this.priceMultiplier);

  final String label;
  final double priceMultiplier;
}
