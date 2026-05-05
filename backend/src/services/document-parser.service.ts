import { AppError } from '../lib/errors';
import {
  ParsedDocument,
  ParsedLineItem,
  documentKindSchema,
  type DocumentKind,
} from '../lib/document-types';

function normalizeText(rawText: string) {
  return rawText
    .replace(/\r/g, '')
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean);
}

function parseMoneySegment(segment: string) {
  const cleaned = segment.replace(/[^\d.*]/g, '').trim();
  if (!cleaned) {
    return { unitPrice: 0, quantity: 1, total: 0 };
  }

  if (cleaned.includes('*')) {
    const [unitRaw, quantityRaw] = cleaned.split('*');
    const unitPrice = Number(unitRaw);
    const quantity = Number(quantityRaw);
    const total = unitPrice * quantity;
    return {
      unitPrice: Number.isFinite(unitPrice) ? unitPrice : 0,
      quantity: Number.isFinite(quantity) ? quantity : 1,
      total: Number.isFinite(total) ? total : 0,
    };
  }

  const value = Number(cleaned);
  return {
    unitPrice: Number.isFinite(value) ? value : 0,
    quantity: 1,
    total: Number.isFinite(value) ? value : 0,
  };
}

function parseLineItem(line: string): ParsedLineItem {
  const segments = line.split(/\s+-\s+/).map((segment) => segment.trim()).filter(Boolean);
  if (segments.length < 2) {
    throw new AppError(400, `Unable to parse line item "${line}". Use "Description - 100" style entries.`);
  }

  const description = segments[0];
  const firstMoney = parseMoneySegment(segments[1]);
  const explicitTotal = segments[2] ? Number(segments[2].replace(/[^\d.]/g, '')) : null;
  const total = explicitTotal != null && Number.isFinite(explicitTotal) ? explicitTotal : firstMoney.total;

  return {
    description,
    quantity: firstMoney.quantity,
    unitPrice: firstMoney.unitPrice,
    total,
  };
}

function detectType(firstLine: string): DocumentKind {
  const normalized = firstLine.trim().toLowerCase();
  if (normalized == 'invoice') {
    return 'invoice';
  }
  if (normalized == 'quotation' || normalized == 'quote') {
    return 'quotation';
  }
  if (normalized == 'estimation' || normalized == 'estimate') {
    return 'estimation';
  }
  throw new AppError(400, 'Document must start with Invoice, Quotation/Quote, or Estimation/Estimate.');
}

export function parseOwnerDocumentInput(rawText: string): ParsedDocument {
  const lines = normalizeText(rawText);
  if (lines.length < 5) {
    throw new AppError(400, 'Document input is incomplete. Expected document type, vehicle, model, customer, and at least one line item.');
  }

  const type = documentKindSchema.parse(detectType(lines[0]));
  const vehicleNumber = lines[1];
  const carModel = lines[2];
  const customerName = lines[3];
  const itemLines = lines.slice(4);
  const items = itemLines.map(parseLineItem);
  const subtotal = items.reduce((sum, item) => sum + item.total, 0);

  return {
    type,
    vehicleNumber,
    carModel,
    customerName,
    items,
    subtotal,
    total: subtotal,
    sourceText: rawText,
  };
}

