// Formata a data por extenso nos painéis dos três fluxos da clínica.
String formatarDataExtensa(DateTime data) {
  const meses = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  return '${data.day} de ${meses[data.month - 1]} de ${data.year}';
}
