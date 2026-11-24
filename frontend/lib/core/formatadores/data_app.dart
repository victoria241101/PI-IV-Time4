// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: Formatação de datas por extenso.
// Formata a data por extenso nos painéis dos três fluxos da clínica.
String formatarDataExtensa(DateTime data) {
  // Os nomes em português não dependem da configuração regional do aparelho.
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
  // Monta o formato completo usado pelos cabeçalhos dos painéis.
  return '${data.day} de ${meses[data.month - 1]} de ${data.year}';
}
