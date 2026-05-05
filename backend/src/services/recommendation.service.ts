import { ParsedLineItem } from '../lib/document-types';

const modelRecommendations: Record<string, string[]> = {
  hector: ['DPF additive', 'Engineoil(fullysynth 5w30)', 'Cabinfilter'],
  creta: ['Airfilter', 'Wheel alignment', 'Engine oil'],
  swift: ['Oilfilter', 'Brake cleaning', 'Coolant top-up'],
};

export function buildServiceSuggestions(carModel: string, historicalItems: ParsedLineItem[]) {
  const modelKey = carModel.toLowerCase();
  const seedSuggestions = Object.entries(modelRecommendations).find(([key]) => modelKey.includes(key))?.[1] ?? [
    'Periodic maintenance inspection',
    'Brake inspection',
    'Battery health check',
  ];

  const historicalKeywords = historicalItems
    .map((item) => item.description)
    .filter((value, index, list) => list.indexOf(value) === index)
    .slice(0, 3);

  return [...seedSuggestions, ...historicalKeywords].filter((value, index, list) => list.indexOf(value) === index);
}
