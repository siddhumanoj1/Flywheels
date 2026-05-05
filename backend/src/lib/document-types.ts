import { z } from 'zod';

export const documentKindSchema = z.enum(['invoice', 'quotation', 'estimation']);
export type DocumentKind = z.infer<typeof documentKindSchema>;

export interface ParsedLineItem {
  description: string;
  quantity: number;
  unitPrice: number;
  total: number;
}

export interface ParsedDocument {
  type: DocumentKind;
  vehicleNumber: string;
  carModel: string;
  customerName: string;
  items: ParsedLineItem[];
  subtotal: number;
  total: number;
  sourceText: string;
}

export function documentNumberPrefix(type: DocumentKind) {
  switch (type) {
    case 'invoice':
      return 'INV';
    case 'quotation':
      return 'QTN';
    case 'estimation':
      return 'EST';
  }
}

